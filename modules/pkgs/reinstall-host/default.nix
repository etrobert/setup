{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = self.lib.onlySupported {
        reinstall-host = pkgs.writeShellApplication {
          name = "reinstall-host";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = [
            pkgs.bitwarden-cli
            pkgs.coreutils
            pkgs.nixos-anywhere
            pkgs.openssh
          ];
          inheritPath = false;
          # Usage: BW_SESSION=… reinstall-host <host> <target> [flake]
          text = ''
            host=$1
            target=$2
            flake=''${3:-github:etrobert/setup}

            secrets=$(mktemp --directory)
            trap 'rm -rf "$secrets"' EXIT

            # agenix decrypts with the host key, so the new install must get the old one.
            install -d -m 755 "$secrets/extra/etc/ssh"
            key="$secrets/extra/etc/ssh/ssh_host_ed25519_key"
            bw get notes "$host ssh host key" > "$key"
            chmod 600 "$key"
            ssh-keygen -y -f "$key" > "$key.pub"

            # No trailing newline: cryptsetup would make it part of the passphrase.
            printf '%s' "$(bw get password "$host disk passphrase")" > "$secrets/disk.key"

            nixos-anywhere \
              --flake "$flake#$host" \
              --extra-files "$secrets/extra" \
              --disk-encryption-keys /tmp/disk.key "$secrets/disk.key" \
              --target-host "$target"
          '';
        };
      };
    };
}

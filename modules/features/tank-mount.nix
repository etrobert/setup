# tower's tank share on client machines, credentials from the shared
# smb-credentials secret.
_: {
  flake = {
    # Mounted at /mnt/tank on first access, so boot never depends on tower
    # being reachable.
    nixosModules.tankMount =
      { config, ... }:
      {
        age.secrets.smb-credentials.file = ../../secrets/smb-credentials.age;

        fileSystems."/mnt/tank" = {
          device = "//tower/tank";
          fsType = "cifs";

          options = [
            "credentials=${config.age.secrets.smb-credentials.path}"
            "uid=soft"
            "x-systemd.automount"
          ];
        };
      };

    # macOS has no on-access automount: a launchd user agent mounts at login
    # instead. If tower is unreachable then (e.g. Tailscale not yet up), the
    # attempt fails quietly; retrigger with
    #   launchctl kickstart gui/$UID/org.nixos.tank-mount
    darwinModules.tankMount =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        tank-mount = pkgs.writeShellApplication {
          name = "tank-mount";

          runtimeInputs = [
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.gnused
            pkgs.jq
          ];

          inheritPath = false;

          text = /* bash */ ''
            mountpoint="$HOME/tank"

            if /sbin/mount | grep --quiet " on $mountpoint ("; then
              exit 0
            fi

            mkdir -p "$mountpoint"

            # mount_smbfs (an Apple system binary, hence the absolute path)
            # takes credentials only via the URL, so the password must be
            # URI-encoded.
            password="$(sed --quiet 's/^password=//p' ${config.age.secrets.smb-credentials.path})"
            encoded="$(jq --raw-output --null-input --arg v "$password" '$v|@uri')"
            exec /sbin/mount_smbfs "//soft:$encoded@tower/tank" "$mountpoint"
          '';
        };
      in
      {
        age.secrets.smb-credentials = {
          file = ../../secrets/smb-credentials.age;
          owner = "soft";
        };

        launchd.user.agents.tank-mount = {
          serviceConfig = {
            ProgramArguments = [ (lib.getExe tank-mount) ];
            RunAtLoad = true;
          };
        };
      };
  };
}

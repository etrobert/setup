{ inputs, ... }:
{
  flake =
    let
      agenixModule =
        sudo:
        { pkgs, ... }:
        {
          # agenix decrypts with this host's key, copied out so the CLI runs as the user.
          environment.systemPackages = [
            (pkgs.writeShellApplication {
              name = "agenix";
              inheritPath = false;
              runtimeInputs = [
                inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
                pkgs.coreutils
              ];
              text = ''
                identity=$(mktemp)
                trap 'rm -f "$identity"' EXIT
                ${sudo} cp /etc/ssh/ssh_host_ed25519_key "$identity"
                agenix --identity "$identity" "$@"
              '';
            })
          ];
        };
    in
    {
      nixosModules.agenix = agenixModule "/run/wrappers/bin/sudo";
      darwinModules.agenix = agenixModule "/usr/bin/sudo";
    };
}

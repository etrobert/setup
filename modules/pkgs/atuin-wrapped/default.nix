{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      system,
      ...
    }:
    let
      # atuin 18.24.x fails to build on aarch64 (NixOS/nixpkgs#578686), so the cache lacks it
      atuin =
        if system == "aarch64-linux" then
          inputs.nixpkgs-atuin.legacyPackages.${system}.atuin
        else
          pkgs.atuin;
    in
    {
      packages.atuin-wrapped =
        let
          configFile = (pkgs.formats.toml { }).generate "atuin-config.toml" {
            # Self-hosted (modules/features/atuin-server.nix), so sync_protocol = Auto
            # picks the legacy protocol rather than Hub. Plaintext inside WireGuard.
            sync_address = "http://tower:8888";
            sync_frequency = "0";

            ui.columns = [
              "exit"
              "duration"
              "time"
              # Narrower than the default 15: the longest hostname here is "charon".
              {
                type = "host";
                width = 6;
              }
              "command"
            ];
          };

          configDir = pkgs.linkFarm "atuin-config" [
            {
              name = "config.toml";
              path = configFile;
            }
          ];
        in
        self'.legacyPackages.wrapPackage {
          package = atuin;
          setDefaults.ATUIN_CONFIG_DIR = configDir;
        };
    };
}

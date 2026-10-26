{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      system,
      ...
    }:
    let
      # atuin 18.24.2 fails its tests on aarch64 (NixOS/nixpkgs#578686), so the cache lacks it
      atuin =
        assert lib.assertMsg (pkgs.atuin.version == "18.24.2")
          "nixpkgs atuin is past 18.24.2: drop the nixpkgs-atuin pin in modules/pkgs/atuin-wrapped and flake.nix";
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
            sync_address = "http://charon:8888";
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

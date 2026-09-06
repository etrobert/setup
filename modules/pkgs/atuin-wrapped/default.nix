_: {
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages.atuin-wrapped =
        let
          configFile = (pkgs.formats.toml { }).generate "atuin-config.toml" {
            # Self-hosted (modules/features/atuin-server.nix), so sync_protocol = Auto
            # picks the legacy protocol rather than Hub. Plaintext inside WireGuard.
            sync_address = "http://tower:8888";

            ui.columns = [
              "exit"
              "duration"
              "time"
              # Narrower than the default 15: the longest hostname here is "tower".
              {
                type = "host";
                width = 5;
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
        config.lib.wrapPackage {
          package = pkgs.atuin;
          setDefaults.ATUIN_CONFIG_DIR = configDir;
        };
    };
}

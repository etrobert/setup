{
  atuin,
  wrapPackage,
  linkFarm,
  formats,
}:
let
  configFile = (formats.toml { }).generate "atuin-config.toml" {
    # Self-hosted (modules/features/atuin-server.nix), so sync_protocol = Auto
    # picks the legacy protocol rather than Hub. Plaintext inside WireGuard.
    sync_address = "http://tower:8888";

    ui.columns = [
      "exit"
      "duration"
      "time"
      "command"
    ];
  };

  configDir = linkFarm "atuin-config" [
    {
      name = "config.toml";
      path = configFile;
    }
  ];
in
wrapPackage {
  package = atuin;
  setDefaults.ATUIN_CONFIG_DIR = configDir;
}

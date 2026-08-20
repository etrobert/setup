{
  atuin,
  wrapPackage,
  linkFarm,
  formats,
}:
let
  configFile = (formats.toml { }).generate "atuin-config.toml" {
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

# Wraps atuin with ATUIN_CONFIG_DIR pointed at a baked config.toml, so the
# interactive search UI is declared here rather than in a hand-edited
# ~/.config/atuin/config.toml. --set-default, so an ad-hoc override still wins.
{
  atuin,
  wrapPackage,
  linkFarm,
  formats,
}:
let
  # Stock columns are duration/time/command. `exit` is why atuin is here at
  # all: zsh's history file records no exit status. Leftmost so failures are
  # scannable down the edge of the list. `command` must stay last — it is the
  # column that expands to fill.
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

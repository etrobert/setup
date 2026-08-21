{
  inputs',
  wrapPackage,
  linkFarm,
  git-wrapped,
  tmux-wrapped,
}:
let
  configHome = linkFarm "workmux-config-home" [
    {
      name = "workmux/config.yaml";
      path = ./config.yaml;
    }
  ];
in
wrapPackage {
  package = inputs'.workmux.packages.default;

  # Upstream's flake sets no meta.mainProgram.
  mainProgram = "workmux";

  env = {
    # workmux reads its global config only from $XDG_CONFIG_HOME/workmux — it
    # has no flag or dedicated variable for it, so the whole XDG root has to
    # move. tmux-wrapped passes -f and claude-code-wrapped sets
    # CLAUDE_CONFIG_DIR, so the processes workmux spawns keep their own config.
    XDG_CONFIG_HOME = configHome;
    WORKMUX_NO_UPDATE_CHECK = "1";
  };

  inheritPath = true;

  runtimeInputs = [
    git-wrapped
    tmux-wrapped
  ];
}

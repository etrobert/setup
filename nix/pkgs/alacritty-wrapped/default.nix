{
  symlinkJoin,
  makeWrapper,
  alacritty,
  writeText,
}:
let
  configFile = writeText "alacritty.toml" /* toml */ ''
    [env]
    TERM = "xterm-256color"

    [window]
    padding.x = 10
    padding.y = 10
    dimensions.columns = 0
    dimensions.lines = 0

    decorations = "Buttonless"

    opacity = 1
    blur = true

    option_as_alt = "Both"

    [font]
    normal.family = "FiraCode Nerd Font"
    size = 13

    [general]
    import = [ "${./catppuccin-macchiato.toml}" ]
  '';
in
# TODO: --set PATH
symlinkJoin {
  name = "alacritty-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ alacritty ];
  meta.mainProgram = "alacritty";
  postBuild = ''
    wrapProgram $out/bin/alacritty \
      --add-flags "--config-file ${configFile}"
  '';
}

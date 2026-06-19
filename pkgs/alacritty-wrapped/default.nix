{
  alacritty,
  writeText,
  wrapPackage,
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
# alacritty ships a .desktop file referencing the unwrapped binary, but it
# uses the Exec= value from $PATH at launch time, so no filesToPatch needed.
wrapPackage {
  package = alacritty;
  flags = [ "--config-file ${configFile}" ];
}

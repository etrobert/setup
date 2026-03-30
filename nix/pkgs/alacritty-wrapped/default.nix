{
  symlinkJoin,
  makeWrapper,
  alacritty,
  writeText,
}:
let
  configFile = writeText "alacritty.toml" (
    builtins.replaceStrings [ "__CATPPUCCIN_MACCHIATO__" ] [ (toString ./catppuccin-macchiato.toml) ] (
      builtins.readFile ./alacritty.toml
    )
  );
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

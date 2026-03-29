{
  writeShellApplication,
  symlinkJoin,
  makeWrapper,
  lib,
  waybar,
  coreutils,
  curl,
  jq,
}:
let
  get_weather = writeShellApplication {
    name = "get_weather.sh";
    runtimeInputs = [
      coreutils
      curl
      jq
    ];
    inheritPath = false;
    text = builtins.readFile ../../waybar/.local/bin/get_weather.sh;
  };

in
symlinkJoin {
  name = "waybar-wrapped";
  buildInputs = [ makeWrapper ];
  paths = [ waybar ];
  meta.mainProgram = "waybar";
  postBuild = ''
    wrapProgram $out/bin/waybar \
      --add-flags "--config ${../../waybar/.config/waybar/config.jsonc}" \
      --add-flags "--style ${../../waybar/.config/waybar/style.css}" \
      --prefix PATH : ${lib.makeBinPath [ get_weather ]}
  '';
}

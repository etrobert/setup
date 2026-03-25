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
  postBuild = ''
    wrapProgram $out/bin/waybar \
      --prefix PATH : ${lib.makeBinPath [ get_weather ]}
  '';
}

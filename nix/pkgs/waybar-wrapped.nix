{ pkgs }:
let
  get_weather = pkgs.writeShellApplication {
    name = "get_weather.sh";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
    ];
    inheritPath = false;
    text = builtins.readFile ../../waybar/.local/bin/get_weather.sh;
  };
in
pkgs.symlinkJoin {
  name = "waybar-wrapped";
  buildInputs = [ pkgs.makeWrapper ];
  paths = [ pkgs.waybar ];
  postBuild = ''
    wrapProgram $out/bin/waybar \
      --prefix PATH : ${pkgs.lib.makeBinPath [ get_weather ]}
  '';
}

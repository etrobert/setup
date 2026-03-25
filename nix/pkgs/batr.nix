{ pkgs }:
pkgs.writeShellApplication {
  name = "batr";
  runtimeInputs = with pkgs; [
    findutils
    bat
  ];
  inheritPath = false;
  text = ''find "$1" -type f -exec bat {} +'';
}

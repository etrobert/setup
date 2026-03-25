{ pkgs }:
pkgs.writeShellApplication {
  name = "creme";
  runtimeInputs = with pkgs; [ mpc ];
  inheritPath = false;
  text = builtins.readFile ./creme.sh;
}

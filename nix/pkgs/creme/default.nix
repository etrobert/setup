{ writeShellApplication, mpc }:
writeShellApplication {
  name = "creme";
  runtimeInputs = [ mpc ];
  inheritPath = false;
  text = builtins.readFile ./creme.sh;
}

{ jq, writeShellApplication }:
writeShellApplication {
  name = "claude-url-space";
  runtimeInputs = [ jq ];
  inheritPath = false;
  text = builtins.readFile ./claude-url-space.sh;
}

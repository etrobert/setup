{
  curl,
  jq,
  writeShellApplication,
}:
writeShellApplication {
  name = "claude-speak";
  runtimeInputs = [
    curl
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./claude-speak.sh;
}

{
  coreutils,
  jq,
  writeShellApplication,
}:
writeShellApplication {
  name = "claude-session-host";
  runtimeInputs = [
    coreutils
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./claude-session-host.sh;
}

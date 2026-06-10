{
  coreutils,
  curl,
  gnugrep,
  jq,
  writeShellApplication,
}:
writeShellApplication {
  name = "claude-rate-limit-notify";
  runtimeInputs = [
    coreutils
    curl
    gnugrep
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./claude-rate-limit-notify.sh;
}

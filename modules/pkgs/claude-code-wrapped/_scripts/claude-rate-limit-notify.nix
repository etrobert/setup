{
  coreutils,
  gnugrep,
  jq,
  ntfy-sh,
  writeShellApplication,
}:
writeShellApplication {
  name = "claude-rate-limit-notify";
  runtimeInputs = [
    coreutils
    gnugrep
    jq
    ntfy-sh
  ];
  inheritPath = false;
  text = builtins.readFile ./claude-rate-limit-notify.sh;
}

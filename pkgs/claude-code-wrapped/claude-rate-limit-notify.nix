{
  coreutils,
  gnugrep,
  jq,
  pkgs,
  writeShellApplication,
}:
writeShellApplication {
  name = "claude-rate-limit-notify";
  runtimeInputs = [
    coreutils
    gnugrep
    jq
    pkgs.ntfy-sh
  ];
  inheritPath = false;
  text = builtins.readFile ./claude-rate-limit-notify.sh;
}

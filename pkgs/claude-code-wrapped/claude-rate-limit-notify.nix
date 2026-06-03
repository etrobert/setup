{
  coreutils,
  gnugrep,
  jq,
  libnotify,
  systemd,
  writeShellApplication,
}:
writeShellApplication {
  name = "claude-rate-limit-notify";
  runtimeInputs = [
    coreutils
    gnugrep
    jq
    libnotify
    systemd
  ];
  inheritPath = false;
  text = builtins.readFile ./claude-rate-limit-notify.sh;
}

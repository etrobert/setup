{
  coreutils,
  espeak-ng,
  gnugrep,
  gnused,
  jq,
  pipewire,
  writeShellApplication,
}:
writeShellApplication {
  name = "claude-speak";
  runtimeInputs = [
    coreutils
    espeak-ng
    gnugrep
    gnused
    jq
    pipewire
  ];
  inheritPath = false;
  # SC2016: backtick patterns in sed single-quoted strings are intentional
  # (they are regex literals, not shell expansions).
  excludeShellChecks = [ "SC2016" ];
  text = builtins.readFile ./claude-speak.sh;
}

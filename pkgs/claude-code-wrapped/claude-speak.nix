{
  lib,
  stdenv,
  coreutils,
  espeak-ng,
  gnugrep,
  gnused,
  jq,
  pipewire,
  util-linux,
  writeShellApplication,
}:
writeShellApplication {
  name = "claude-speak";
  # pipewire (pw-play) and util-linux (setsid) are Linux-only in nixpkgs and
  # fail to build on darwin, where the script uses /usr/bin/say instead.
  runtimeInputs = [
    coreutils
    espeak-ng
    gnugrep
    gnused
    jq
  ]
  ++ lib.optionals stdenv.isLinux [
    pipewire
    util-linux
  ];
  inheritPath = false;
  # SC2016: backtick patterns in sed single-quoted strings are intentional
  # (they are regex literals, not shell expansions).
  excludeShellChecks = [ "SC2016" ];
  text = builtins.readFile ./claude-speak.sh;
}

{
  lib,
  stdenv,
  coreutils,
  fetchurl,
  gnugrep,
  gnused,
  jq,
  linkFarm,
  piper-tts,
  pipewire,
  util-linux,
  writeShellApplication,
}:
let
  # Vendored Piper voice (en_US-lessac-medium). Piper's CLI ignores --config and
  # always reads the config as "<model-path>.json" by adjacency, so the .onnx and
  # .onnx.json must live in the same directory — linkFarm colocates them.
  voiceBase = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium";
  voiceModel = fetchurl {
    url = "${voiceBase}/en_US-lessac-medium.onnx";
    hash = "sha256-Xv4J5pkCGHgnr2RuGm6dJp3udp+Yd9F7FrG0buqvAZ8=";
  };
  voiceConfig = fetchurl {
    url = "${voiceBase}/en_US-lessac-medium.onnx.json";
    hash = "sha256-7+GcQXvtBV8taZCCSMa6ZQ+hNbyGiw5quz2hgdq2kKA=";
  };
  voiceDir = linkFarm "piper-voice-lessac-medium" {
    "en_US-lessac-medium.onnx" = voiceModel;
    "en_US-lessac-medium.onnx.json" = voiceConfig;
  };
in
writeShellApplication {
  name = "claude-speak";
  # piper-tts (with pw-play) is the Linux engine; darwin uses /usr/bin/say, so
  # piper, pipewire and util-linux (setsid) are Linux-only — they fail to build
  # on darwin.
  runtimeInputs = [
    coreutils
    gnugrep
    gnused
    jq
  ]
  ++ lib.optionals stdenv.isLinux [
    piper-tts
    pipewire
    util-linux
  ];
  runtimeEnv = {
    PIPER_MODEL = "${voiceDir}/en_US-lessac-medium.onnx";
  };
  inheritPath = false;
  # SC2016: backtick patterns in sed single-quoted strings are intentional
  # (they are regex literals, not shell expansions).
  excludeShellChecks = [ "SC2016" ];
  text = builtins.readFile ./claude-speak.sh;
}

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
  # Vendored Piper voice (en_US-ryan-high). The "high" quality tier (22.05 kHz,
  # larger model) sounds noticeably more natural than the "medium" tier. Piper's
  # CLI ignores --config and always reads the config as "<model-path>.json" by
  # adjacency, so the .onnx and .onnx.json must live in the same directory —
  # linkFarm colocates them.
  voiceBase = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high";
  voiceModel = fetchurl {
    url = "${voiceBase}/en_US-ryan-high.onnx";
    hash = "sha256-s5kNdgbhg+yNv7pwpGBwdPFi3hoMQS4BgNH/YLsVTso=";
  };
  voiceConfig = fetchurl {
    url = "${voiceBase}/en_US-ryan-high.onnx.json";
    hash = "sha256-xtO5jwgxXLS+vw1J1Q/E/0kbUDxkuUDNPVyihUO0gBE=";
  };
  voiceDir = linkFarm "piper-voice-ryan-high" {
    "en_US-ryan-high.onnx" = voiceModel;
    "en_US-ryan-high.onnx.json" = voiceConfig;
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
    PIPER_MODEL = "${voiceDir}/en_US-ryan-high.onnx";
  };
  inheritPath = false;
  text = builtins.readFile ./claude-speak.sh;
}

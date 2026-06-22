{
  coreutils,
  findutils,
  jq,
  writeShellApplication,
  # TTS backend providing the `tts` binary speak pipes text to. Swap the engine
  # by wiring a different tts-*.nix here in default.nix.
  tts,
}:
writeShellApplication {
  name = "speak";
  runtimeInputs = [
    coreutils
    findutils
    jq
    tts
  ];
  inheritPath = false;
  text = builtins.readFile ./speak.sh;
}

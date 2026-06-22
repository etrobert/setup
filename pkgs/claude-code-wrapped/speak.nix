{
  coreutils,
  findutils,
  jq,
  writeShellApplication,
  # TTS backends made available on speak's PATH; the active one is chosen at
  # runtime via $SPEAK_TTS (default tts-say).
  ttsBackends,
}:
writeShellApplication {
  name = "speak";
  runtimeInputs = [
    coreutils
    findutils
    jq
  ]
  ++ ttsBackends;
  inheritPath = false;
  text = builtins.readFile ./speak.sh;
}

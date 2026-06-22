# macOS `say` TTS backend: reads text on stdin and speaks it with the system
# default voice. Implements the `tts-*` interface consumed by `speak` (stdin in,
# audio out); swap engines at runtime via $SPEAK_TTS.
{
  writeShellApplication,
}:
writeShellApplication {
  name = "tts-say";
  inheritPath = false;
  text = ''
    say_bin=/usr/bin/say
    if [ ! -x "$say_bin" ]; then
      echo "tts-say: $say_bin not found (macOS only)" >&2
      exit 1
    fi
    exec "$say_bin"
  '';
}

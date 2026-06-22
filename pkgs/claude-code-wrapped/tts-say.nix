# macOS `say` TTS backend: reads text on stdin and speaks it with the system
# default voice. Provides the `tts` interface consumed by `speak` (stdin in,
# audio out); the active engine is chosen by the backend wired in default.nix.
{
  writeShellApplication,
}:
writeShellApplication {
  name = "tts";
  inheritPath = false;
  text = ''
    say_bin=/usr/bin/say
    if [ ! -x "$say_bin" ]; then
      echo "tts: $say_bin not found (macOS only)" >&2
      exit 1
    fi
    exec "$say_bin"
  '';
}

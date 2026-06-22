# Piper TTS backend: reads text on stdin and speaks it with a local neural voice
# (en_US-ryan-high). Implements the `tts-*` interface consumed by `speak`
# (stdin in, audio out); swap engines at runtime via $SPEAK_TTS.
#
# Piper is fully local (no cloud, no cost) and cross-platform. Unlike macOS
# `say`, it only produces audio samples, so this backend plays them itself:
# afplay on macOS, paplay on Linux.
#
# Uses the nixpkgs `piper-tts` package directly — no wheel hashes to pin or
# version matrix to maintain. That package propagates piper's training stack
# (torch, pytorch-lightning, tensorboard, pysilero-vad) as runtime deps, so the
# closure is ~2.9 GB; but synthesis runs through onnxruntime and never imports
# them, so there is no runtime cost — the price is purely disk.
#
# The voice model itself is not packaged in nixpkgs (only the engine is), so it
# is fetched below. Unlike a wheel, it is a single immutable artifact: the hash
# is set once and never needs bumping.
{
  lib,
  stdenv,
  fetchurl,
  runCommand,
  piper-tts,
  coreutils,
  pulseaudio,
  writeShellApplication,
}:
let
  # Bundle the default voice (model + its config) in one store path so the
  # wrapper can point piper at it.
  ryanHigh = runCommand "piper-voice-en_US-ryan-high" { } ''
    mkdir -p $out
    cp ${
      fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx";
        hash = "sha256-s5kNdgbhg+yNv7pwpGBwdPFi3hoMQS4BgNH/YLsVTso=";
      }
    } $out/en_US-ryan-high.onnx
    cp ${
      fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx.json";
        hash = "sha256-xtO5jwgxXLS+vw1J1Q/E/0kbUDxkuUDNPVyihUO0gBE=";
      }
    } $out/en_US-ryan-high.onnx.json
  '';

  # Referencing paplay by absolute store path pulls PulseAudio into the closure
  # only on Linux; on macOS afplay is a bare string (built into the OS), so the
  # dependency stays off the Darwin closure.
  player = if stdenv.isDarwin then "/usr/bin/afplay" else "${pulseaudio}/bin/paplay";
in
writeShellApplication {
  name = "tts-piper";
  runtimeInputs = [
    piper-tts
    coreutils
  ];
  inheritPath = false;
  text = ''
    model="${ryanHigh}/en_US-ryan-high.onnx"

    # piper only emits audio samples, so synthesize to a temp WAV and play it.
    wav=$(mktemp --tmpdir tts-piper.XXXXXX.wav)
    trap 'rm --force "$wav"' EXIT

    # piper reads the text to speak on stdin and writes a WAV to --output-file.
    piper --model "$model" --output-file "$wav"

    ${player} "$wav"
  '';
}

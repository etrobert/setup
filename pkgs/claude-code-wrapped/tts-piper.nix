# Piper TTS backend: reads text on stdin and speaks it with a local neural voice
# (default en_US-ryan-high). Implements the `tts-*` interface consumed by
# `speak` (stdin in, audio out); swap engines at runtime via $SPEAK_TTS.
#
# Piper is fully local (no cloud, no cost) and cross-platform. Unlike macOS
# `say`, it only produces audio samples, so this backend plays them itself:
# afplay on macOS, paplay on Linux.
#
# Override the voice with $SPEAK_PIPER_VOICE set to an absolute path to a
# `<voice>.onnx` file (its `.onnx.json` must sit beside it). Default is the
# bundled ryan-high.
#
# Packaged from the upstream v1.4.2 wheel: nixpkgs `piper-tts` is broken
# (its training dep pysilero-vad is marked broken) and the prebuilt macOS
# standalone binary ships no dylibs. The wheel needs only onnxruntime + numpy
# (espeak-ng is bundled inside it), so the closure stays light (no torch).
{
  lib,
  stdenv,
  fetchurl,
  runCommand,
  python3,
  coreutils,
  pulseaudio,
  autoPatchelfHook,
  writeShellApplication,
}:
let
  version = "1.4.2";
  wheels = {
    aarch64-darwin = {
      url = "https://files.pythonhosted.org/packages/47/e1/84fcb36c7ac413bb22eb3bdda5f21861f02d0f436df0a9090949c9fec032/piper_tts-1.4.2-cp39-abi3-macosx_11_0_arm64.whl";
      hash = "sha256-E45q3yao55b1OGZ3DqMLZmtlQypelIV8LZqMRzqKH5A=";
    };
    aarch64-linux = {
      url = "https://files.pythonhosted.org/packages/77/1c/260c65320df47fee582d78ad52d49d4195c5439a77b62e73306c2de835ea/piper_tts-1.4.2-cp39-abi3-manylinux_2_17_aarch64.manylinux2014_aarch64.manylinux_2_28_aarch64.whl";
      hash = "sha256-ZzYynx71jDknIhWEnf/ayuYBIBSAsIoMiSk4+k18jGc=";
    };
    x86_64-linux = {
      url = "https://files.pythonhosted.org/packages/a7/58/7b7cbd7e570ac6eb8dbfc22de94d1457863b97876c1cb6a926e959423fb2/piper_tts-1.4.2-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.manylinux_2_28_x86_64.whl";
      hash = "sha256-sXGEpmS9lDHOlcE49L+zAl4SgM8mB1pwPb/cq5ibjuM=";
    };
  };
  wheel =
    wheels.${stdenv.hostPlatform.system}
      or (throw "tts-piper: no piper-tts wheel for ${stdenv.hostPlatform.system}");

  piper-tts = python3.pkgs.buildPythonPackage {
    pname = "piper-tts";
    inherit version;
    format = "wheel";
    src = fetchurl wheel;
    propagatedBuildInputs = with python3.pkgs; [
      onnxruntime
      numpy
      pathvalidate
    ];
    # The manylinux wheel bundles native extensions (espeakbridge, libespeak-ng)
    # that need patching against the Nix loader.
    nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
    buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];
    dontStrip = true;
    pythonImportsCheck = [ "piper" ];
  };

  pythonEnv = python3.withPackages (_ps: [ piper-tts ]);

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
in
writeShellApplication {
  name = "tts-piper";
  runtimeInputs = [
    pythonEnv
    coreutils
  ]
  ++ lib.optionals stdenv.isLinux [ pulseaudio ];
  inheritPath = false;
  text = ''
    model="''${SPEAK_PIPER_VOICE:-${ryanHigh}/en_US-ryan-high.onnx}"
    if [ ! -f "$model" ]; then
      echo "tts-piper: voice model not found: $model" >&2
      exit 1
    fi

    wav=$(mktemp -t tts-piper.XXXXXX.wav)
    trap 'rm -f "$wav"' EXIT

    # piper reads the text to speak on stdin and writes a WAV to -f.
    python -m piper --model "$model" --output-file "$wav"

    case "$(uname)" in
      Darwin) /usr/bin/afplay "$wav" ;;
      *) paplay "$wav" ;;
    esac
  '';
}

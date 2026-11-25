# Hold Super+D to dictate into the focused window, or tap it to toggle.
{ self, ... }:
{
  flake.nixosModules.dictation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      vocabulary = "Tanzfabrik, Amílcar, Nix, NixOS, nixpkgs, flake, niri, Noctalia, Tailscale, tmux, Neovim, agenix, systemd, PipeWire, Kanata, Claude Code, GitHub, pull request, leod.";

      dictation = pkgs.writeShellApplication {
        name = "dictation";
        inheritPath = false;
        runtimeInputs = with pkgs; [
          coreutils
          curl
          gnused
          libnotify
          pipewire
          socat
          sox
          self.packages.${stdenv.hostPlatform.system}.dictation-lock
          self.packages.${stdenv.hostPlatform.system}.wl-ime-stream
        ];
        text = /* bash */ ''
          recording="$XDG_RUNTIME_DIR/dictation.raw"

          transcribe() {
            tail --bytes=+$(($1 + 1)) "$recording" |
              # Vorbis is a tenth of the size of WAV, which matters on a slow uplink.
              sox --type raw --rate 16000 --encoding signed-integer --bits 16 \
                --channels 1 - --type vorbis --compression 0 - |
              curl --silent --show-error --fail \
                --form file=@- \
                --form response_format=text \
                --form-string ${lib.escapeShellArg "prompt=${vocabulary}"} \
                ${config.dictation.server}/v1/audio/transcriptions |
              tr '\n' ' ' |
              sed --regexp-extended 's/ +/ /g; s/^ | $//g'
          }

          # Each pause ends a segment, so a pass only transcribes what was said since.
          pass() {
            size=$(stat --format=%s "$recording")
            # The server rejects a recording with no audio.
            ((size > start)) || return 0
            text=$(transcribe "$start")
            echo "$committed $text"
            if [ "$text" = "$previous" ]; then ((++same)); else same=1; fi
            previous=$text
            # dictation-lock's PAUSE, so the segment ends as dictation-lock locks it.
            if ((same == 6)); then
              committed+=" $text"
              # Whole 16-bit samples.
              start=$((size - size % 2))
              previous=""
              same=0
            fi
          }

          preview() {
            stopping=false
            trap stopping=true TERM
            committed="" start=0 previous="" same=0
            until "$stopping"; do
              sleep 0.2
              pass
            done
            # The recorder has stopped, so this pass hears everything.
            pass
          }

          latched=false

          while read -r message; do
            case "$message" in
              *dictate-start*)
                "$latched" && continue
                pressed=''${EPOCHREALTIME/./}
                pw-record --raw --rate 16000 --channels 1 --format s16 "$recording" &
                recorder=$!
                exec {typing}> >(dictation-lock | wl-ime-stream)
                typer=$!
                preview >&"$typing" &
                previewer=$!
                ;;
              *dictate-stop*)
                if ! "$latched" && ((''${EPOCHREALTIME/./} - pressed < 300000)); then
                  latched=true
                  notify-send --wait --expire-time 0 Dictation Listening &
                  indicator=$!
                  continue
                fi
                if "$latched"; then
                  latched=false
                  # On SIGINT notify-send closes the notification.
                  # It has already exited if the notification was dismissed.
                  kill -s INT "$indicator" || true
                fi
                kill -s INT "$recorder"
                wait "$recorder" || true
                kill "$previewer"
                wait "$previewer"
                exec {typing}>&-
                wait "$typer" || notify-send Dictation "No text field"
                ;;
            esac
          done < <(socat -u TCP:127.0.0.1:${toString config.ports.kanata} -)
        '';
      };
    in
    {
      options.dictation.server = lib.mkOption {
        type = lib.types.str;
        description = "Base URL of the speech-to-text server.";
        example = "http://127.0.0.1:8080";
      };

      config = {
        assertions = [
          {
            assertion = lib.versionOlder pkgs.niri.version "26.05";
            message = "niri ${pkgs.niri.version} has press/release binds: replace the Kanata push-msg hotkey with one";
          }
        ];

        ports.kanata = "auto";

        services.kanata.keyboards.default.port = config.ports.kanata;

        kanata = {
          keys.d = "@dictate";
          extraConfig = /* scheme */ ''
            (defvirtualkeys dictate-stop (push-msg "dictate-stop"))

            (defalias dictate
              (fork
                d
                (multi (push-msg "dictate-start") (on-release tap-vkey dictate-stop))
                (lmet rmet)))
          '';
        };

        systemd.user.services.dictation = {
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = lib.getExe dictation;
            Restart = "always";
            RestartSec = 1;
          };
        };
      };
    };
}

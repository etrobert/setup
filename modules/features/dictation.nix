# Hold Super+D to dictate into the focused window.
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
      vocabulary = "Nix, NixOS, nixpkgs, flake, niri, Noctalia, Tailscale, tmux, Neovim, agenix, systemd, PipeWire, Kanata, Claude Code, GitHub, pull request, leod.";

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
            # Vorbis is a tenth of the size of WAV, which matters on a slow uplink.
            sox --type raw --rate 16000 --encoding signed-integer --bits 16 \
              --channels 1 "$recording" --type vorbis --compression 0 - |
              curl --silent --show-error --fail \
                --form file=@- \
                --form response_format=text \
                --form-string ${lib.escapeShellArg "prompt=${vocabulary}"} \
                ${config.dictation.server}/v1/audio/transcriptions |
              tr '\n' ' ' |
              sed --regexp-extended 's/ +/ /g; s/^ | $//g'
          }

          preview() {
            while sleep 0.2; do
              # The server rejects a recording with no audio yet.
              [ -s "$recording" ] || continue
              # Captured first, so a pass killed midway writes nothing.
              text=$(transcribe)
              echo "$text"
            done
          }

          while read -r message; do
            case "$message" in
              *dictate-start*)
                pw-record --raw --rate 16000 --channels 1 --format s16 "$recording" &
                recorder=$!
                exec {typing}> >(dictation-lock | wl-ime-stream)
                typer=$!
                preview >&"$typing" &
                previewer=$!
                ;;
              *dictate-stop*)
                kill "$previewer"
                kill -s INT "$recorder"
                wait "$previewer" "$recorder" || true
                text=$(transcribe)
                echo "$text" >&"$typing"
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

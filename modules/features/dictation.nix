# Hold the mic-mute key to dictate into the focused window.
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
          noctalia
          pipewire
          socat
          sox
          self.packages.${stdenv.hostPlatform.system}.wl-ime-type
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

          show() {
            noctalia msg plugin etrobert/dictation:control all "$@" > /dev/null
          }

          preview() {
            while sleep 0.2; do
              show text "$(transcribe)"
            done
          }

          while read -r message; do
            case "$message" in
              *dictate-start*)
                pw-record --raw --rate 16000 --channels 1 --format s16 "$recording" &
                recorder=$!
                show text ""
                preview &
                previewer=$!
                ;;
              *dictate-stop*)
                kill "$previewer"
                kill -s INT "$recorder"
                wait "$previewer" "$recorder" || true
                text=$(transcribe)
                # Nothing answers when the focused window has no text field.
                if [ -n "$text" ] && ! timeout 0.5 wl-ime-type -- "$text"; then
                  show text "No text field"
                  sleep 2
                fi
                show hide
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
          keys.micmute = "@dictate";
          # Mod passes the key through, for the compositor's mic-mute bind.
          extraConfig = /* scheme */ ''
            (deflocalkeys-linux micmute 248)

            (defvirtualkeys dictate-stop (push-msg "dictate-stop"))

            (defalias dictate
              (fork
                (multi (push-msg "dictate-start") (on-release tap-vkey dictate-stop))
                micmute
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

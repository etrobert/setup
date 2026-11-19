# Hold the mic-mute key to dictate into the focused window.
_: {
  flake.nixosModules.dictation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      model = pkgs.fetchurl {
        url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin";
        hash = "sha256-H8cPd0046xaZk6w5Huo1fvR8iHV+9y7llDh5t+jivGk=";
      };

      vocabulary = "Nix, NixOS, nixpkgs, flake, niri, Noctalia, Tailscale, tmux, Neovim, agenix, systemd, PipeWire, Kanata, Claude Code, GitHub, pull request, leod.";

      dictation = pkgs.writeShellApplication {
        name = "dictation";
        inheritPath = false;
        runtimeInputs = with pkgs; [
          coreutils
          curl
          gnused
          pipewire
          socat
          wtype
        ];
        text = /* bash */ ''
          recording="$XDG_RUNTIME_DIR/dictation.wav"

          while read -r message; do
            case "$message" in
              *dictate-start*)
                pw-record --rate 16000 --channels 1 --format s16 "$recording" &
                recorder=$!
                ;;
              *dictate-stop*)
                kill -s INT "$recorder"
                wait "$recorder" || true
                text=$(
                  curl --silent --show-error --fail \
                    --form "file=@$recording" \
                    --form response_format=text \
                    --form-string ${lib.escapeShellArg "prompt=${vocabulary}"} \
                    http://127.0.0.1:${toString config.ports.whisper-server}/v1/audio/transcriptions |
                    tr '\n' ' ' |
                    sed --regexp-extended 's/ +/ /g; s/^ | $//g'
                )
                wtype -- "$text"
                ;;
            esac
          done < <(socat -u TCP:127.0.0.1:${toString config.ports.kanata} -)
        '';
      };
    in
    {
      assertions = [
        {
          assertion = lib.versionOlder pkgs.niri.version "26.05";
          message = "niri ${pkgs.niri.version} has press/release binds: replace the Kanata push-msg hotkey with one";
        }
      ];

      ports = {
        whisper-server = "auto";
        kanata = "auto";
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.ports.whisper-server ];

      systemd.services.whisper-server = {
        wantedBy = [ "multi-user.target" ];
        environment.XDG_CACHE_HOME = "/var/cache/whisper-server";
        serviceConfig = {
          ExecStart = lib.concatStringsSep " " [
            (lib.getExe' pkgs.whisper-cpp-vulkan "whisper-server")
            "--model ${model}"
            "--language auto"
            "--host 0.0.0.0"
            "--port ${toString config.ports.whisper-server}"
            "--inference-path /v1/audio/transcriptions"
          ];
          DynamicUser = true;
          CacheDirectory = "whisper-server";
          Restart = "on-failure";
        };
      };

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
}

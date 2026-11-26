# Speech-to-text over an OpenAI-shaped HTTP endpoint, reachable on the tailnet.
_: {
  flake.nixosModules.whisper-server =
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

      # Without it Whisper transcribes silence as "Thank you."
      voiceActivityModel = pkgs.fetchurl {
        url = "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v5.1.2.bin";
        hash = "sha256-KZQNmNQrkfvQXOSJ8+z3xy8KQvAn5IdZGaKPtMBOos8=";
      };
    in
    {
      ports.whisper-server = "auto";

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.ports.whisper-server ];

      systemd.services.whisper-server = {
        wantedBy = [ "multi-user.target" ];
        environment.XDG_CACHE_HOME = "/var/cache/whisper-server";
        serviceConfig = {
          # Started before the GPU is ready, whisper-server silently falls back to the CPU.
          ExecStartPre = lib.getExe (
            pkgs.writeShellApplication {
              name = "whisper-server-wait-for-gpu";
              inheritPath = false;
              runtimeInputs = with pkgs; [
                gnugrep
                vulkan-tools
              ];
              text = ''
                vulkaninfo --summary | grep --quiet 'deviceType *= PHYSICAL_DEVICE_TYPE_.*_GPU$'
              '';
            }
          );
          ExecStart = lib.concatStringsSep " " [
            (lib.getExe' pkgs.whisper-cpp-vulkan "whisper-server")
            "--model ${model}"
            "--language auto"
            "--vad"
            "--vad-model ${voiceActivityModel}"
            "--host 0.0.0.0"
            "--port ${toString config.ports.whisper-server}"
            "--inference-path /v1/audio/transcriptions"
          ];
          DynamicUser = true;
          CacheDirectory = "whisper-server";
          Restart = "on-failure";
          # Stays under the default start limit of 5 in 10 seconds, so it retries until the GPU shows up.
          RestartSec = 5;
        };
      };
    };
}

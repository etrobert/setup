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

      # Until udev has opened up a render node, whisper-server can't use it and silently falls back to the CPU.
      services.udev.extraRules = ''
        SUBSYSTEM=="drm", KERNEL=="renderD*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="whisper-server.service"
      '';

      systemd.services.whisper-server = {
        environment.XDG_CACHE_HOME = "/var/cache/whisper-server";
        serviceConfig = {
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
        };
      };
    };
}

_: {
  flake.nixosModules.ollama =
    { config, pkgs, ... }:
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.ollama.port ];

      services.ollama = {
        enable = true;
        package = pkgs.ollama-vulkan;

        host = "0.0.0.0";

        environmentVariables.OLLAMA_CONTEXT_LENGTH = "32768";

        loadModels = [ "gpt-oss:20b" ];
      };
    };
}

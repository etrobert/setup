_: {
  flake.nixosModules.ollama =
    { config, ... }:
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.ollama.port ];

      services.ollama = {
        enable = true;
        # TODO: Enable when have GPU
        # package = pkgs.ollama-vulkan;

        host = "0.0.0.0";

        loadModels = [ "qwen2.5-coder:14b" ];
      };
    };
}

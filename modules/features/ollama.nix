# Local text inference on tower's Radeon RX 9070 XT.
#
# Vulkan rather than ROCm: on RDNA4 llama.cpp's Vulkan backend outruns ROCm on
# the small-to-mid GGUF models this serves, and it drops the multi-gigabyte ROCm
# closure from the system.
#
# The model is sized to stay resident in the card's 16 GB. A 14B at Q4_K_M is
# ~9 GB, leaving room for context; the 30B coder models are MoE and need ~19 GB,
# which would spill to CPU.
_: {
  flake.nixosModules.ollama =
    { config, pkgs, ... }:
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.ollama.port ];

      services.ollama = {
        enable = true;
        package = pkgs.ollama-vulkan;

        # Reachable from the other machines over the tailnet; the firewall above
        # is what keeps it off the LAN and the WAN.
        host = "0.0.0.0";

        loadModels = [ "qwen2.5-coder:14b" ];
      };
    };
}

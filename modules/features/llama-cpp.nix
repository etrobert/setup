# Code completion model for Neovim, reachable on the tailnet.
_: {
  flake.nixosModules.llama-cpp =
    { config, pkgs, ... }:
    {
      ports.llama-cpp = "auto";

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.ports.llama-cpp ];

      services.llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp-vulkan;
        settings = {
          model = pkgs.fetchurl {
            url = "https://huggingface.co/mradermacher/Qwen2.5-Coder-7B-GGUF/resolve/main/Qwen2.5-Coder-7B.Q4_K_M.gguf";
            hash = "sha256-krlra/5VQyYF3unEdX7VKsnKCio2Xur3gs5MVyu/rDk=";
          };
          host = "0.0.0.0";
          port = config.ports.llama-cpp;
          # Vulkan1 is the integrated GPU, which llama.cpp would otherwise split layers onto.
          device = "Vulkan0";
          ctx-size = 16384;
          cache-reuse = 256;
          # The default 8 GiB host prompt cache grew by 3 GiB over 60 completions.
          cache-ram = 1024;
        };
      };
    };
}

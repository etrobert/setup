_: {
  flake.nixosModules.comfyui =
    {
      config,
      lib,
      pkgs,
      self,
      ...
    }:
    let
      # rocmSupport at import level so the package's internal torch override
      # inherits it (comfyui.override can't reach that torch).
      pkgsRocm = import pkgs.path {
        inherit (pkgs) system;
        config.rocmSupport = true;
      };

      inherit (pkgsRocm) comfyui;

      # GGUF-quantized checkpoint loaders (UnetLoaderGGUF et al.)
      comfyui-gguf = pkgs.fetchFromGitHub {
        owner = "city96";
        repo = "ComfyUI-GGUF";
        rev = "6ea2651e7df66d7585f6ffee804b20e92fb38b8a";
        hash = "sha256-/ZwecgxTTMo9J1whdEJci8lEkOy/yP+UmjbpOAA3BvU=";
      };

      ggufEnv = comfyui.python.withPackages (ps: [ ps.gguf ]);
    in
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.comfyui.port ];

      services.comfyui = {
        enable = true;
        package = comfyui;

        listen = [ "0.0.0.0" ];

        # Without these, loading a >VRAM model hangs indefinitely on ROCm:
        # https://github.com/Comfy-Org/ComfyUI/issues/13730
        extraArgs = [
          "--disable-dynamic-vram"
          "--disable-pinned-memory"
          "--disable-async-offload"
          "--disable-smart-memory"
        ];
      };

      systemd.services.comfyui = {
        # Started on demand (systemctl start comfyui): ollama preloads
        # gpt-oss:20b into the same 16 GiB of VRAM.
        wantedBy = lib.mkForce [ ];

        environment = {
          PYTHONPATH = "${ggufEnv}/${comfyui.python.sitePackages}";

          # HIP and MIOpen write kernel caches under $HOME
          HOME = "/var/lib/comfyui";
        };

        preStart = lib.mkAfter ''
          ln -sfn ${comfyui-gguf} /var/lib/comfyui/custom_nodes/ComfyUI-GGUF
        '';
      };

      environment.systemPackages = [ self.packages.${pkgs.system}.ltx-t2v ];
    };
}

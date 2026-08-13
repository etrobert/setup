_: {
  flake.nixosModules.comfyui =
    {
      config,
      lib,
      pkgs,
      self,
      nixpkgs-comfyui-pin,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      # rocmSupport at import level so the package's internal torch override
      # inherits it (comfyui.override can't reach that torch).
      pinnedPkgs = import nixpkgs-comfyui-pin {
        inherit system;
        config.rocmSupport = true;
      };

      # GGUF-quantized checkpoint loaders (UnetLoaderGGUF et al.)
      comfyui-gguf = pkgs.fetchFromGitHub {
        owner = "city96";
        repo = "ComfyUI-GGUF";
        rev = "6ea2651e7df66d7585f6ffee804b20e92fb38b8a";
        hash = "sha256-/ZwecgxTTMo9J1whdEJci8lEkOy/yP+UmjbpOAA3BvU=";
      };

      pythonEnv = pinnedPkgs.comfyui.pythonEnv.override (old: {
        extraLibs = old.extraLibs ++ [ pinnedPkgs.comfyui.python.pkgs.gguf ];
      });

      # comfyui's wrapper unsets PYTHONPATH, so gguf only reaches the custom
      # node by rewrapping against an env that already contains it.
      comfyui =
        pkgs.runCommand "comfyui-${pinnedPkgs.comfyui.version}-gguf"
          {
            nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
            meta = pinnedPkgs.comfyui.meta // {
              mainProgram = "comfyui";
            };
          }
          ''
            mkdir -p $out/bin $out/share
            ln -s ${pinnedPkgs.comfyui}/share/comfyui $out/share/comfyui
            makeBinaryWrapper ${pythonEnv}/bin/python $out/bin/comfyui \
              --add-flag $out/share/comfyui/main.py
          '';
    in
    {
      assertions = [
        {
          assertion = lib.versionOlder pkgs.comfyui.version pinnedPkgs.comfyui.version;
          message = "nixos-unstable now has comfyui ${pkgs.comfyui.version}; drop the nixpkgs-comfyui-pin input and use pkgs.comfyui.";
        }
      ];

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

        # HIP and MIOpen write kernel caches under $HOME
        environment.HOME = "/var/lib/comfyui";

        preStart = lib.mkAfter ''
          ln -sfn ${comfyui-gguf} /var/lib/comfyui/custom_nodes/ComfyUI-GGUF

          # seed only; users edit their copies from the UI
          seed() {
            local dest=/var/lib/comfyui/user/default/workflows/"$2"
            [[ -e $dest ]] || install -Dm644 "$1" "$dest"
          }

          seed ${./ltx25-t2v-tower.json} ltx25-t2v-tower.json
          seed ${./ltx25-i2v-tower.json} ltx25-i2v-tower.json
        '';
      };

      environment.systemPackages = [ self.packages.${system}.ltx-video ];
    };
}

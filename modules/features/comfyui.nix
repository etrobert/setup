# nixpkgs' comfyui wires its python env for CUDA/CPU, so re-fix the package
# set with ROCm torch (prebuilt on cache.nixos.org) for the AMD GPU.
#
# Model weights are declared as fetchurl calls below and handed to ComfyUI via
# an extra-model-paths config, so they never need copying into the state dir.
# For gated Hugging Face repos, download once with an auth token and seed the
# store with `nix-store --add-fixed sha256 <file>` — the entry then resolves
# without the URL ever being fetched.
_: {
  flake.nixosModules.comfyui =
    { pkgs, ... }:
    let
      pkgsWithRocmTorch = pkgs.extend (
        _final: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (_pyfinal: pyprev: {
              torch = pyprev.torch.override {
                rocmSupport = true;
                cudaSupport = false;
              };
            })
          ];
        }
      );

      zImageTurbo =
        file: hash:
        pkgs.fetchurl {
          url = "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/d24c4cf2a0cd98a42f23467e27e3d76ee9438b8e/split_files/${file}";
          inherit hash;
        };

      modelDir = pkgs.linkFarm "comfyui-models" {
        "diffusion_models/z_image_turbo_bf16.safetensors" =
          zImageTurbo "diffusion_models/z_image_turbo_bf16.safetensors" "sha256-JAdhMFC4Cf/f8YpKyZr4Pqa5VEPs69+A4GSnnIJVdKY=";

        "text_encoders/qwen_3_4b.safetensors" =
          zImageTurbo "text_encoders/qwen_3_4b.safetensors" "sha256-bGcUmFc6wvelUBUCzM6NKwjqbKL2YcRY5wjzazbt/Fo=";

        "vae/ae.safetensors" =
          zImageTurbo "vae/ae.safetensors" "sha256-r8jignLNFds5GbrNtpGM6cHtIulssSxNXtD7qCNSnjg=";
      };

      modelPathsConfig = (pkgs.formats.yaml { }).generate "extra-model-paths.yaml" {
        nix = {
          base_path = "${modelDir}";
          diffusion_models = "diffusion_models";
          text_encoders = "text_encoders";
          vae = "vae";
        };
      };
    in
    {
      services.comfyui = {
        enable = true;
        package = pkgsWithRocmTorch.comfyui;
        extraArgs = [ "--extra-model-paths-config=${modelPathsConfig}" ];
      };

      # Hide the Ryzen iGPU from HIP so ComfyUI only sees the dGPU
      systemd.services.comfyui.environment.HIP_VISIBLE_DEVICES = "0";
    };
}

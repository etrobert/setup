# nixpkgs' comfyui wires its python env for CUDA/CPU, so re-fix the package
# set with ROCm torch (prebuilt on cache.nixos.org) for the AMD GPU.
_: {
  flake.nixosModules.comfyui =
    { pkgs, ... }:
    let
      pkgsWithRocmTorch = pkgs.extend (
        final: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (pyfinal: pyprev: {
              torch = pyprev.torch.override {
                rocmSupport = true;
                cudaSupport = false;
              };
            })
          ];
        }
      );
    in
    {
      services.comfyui = {
        enable = true;
        package = pkgsWithRocmTorch.comfyui;
      };

      # Hide the Ryzen iGPU from HIP so ComfyUI only sees the dGPU
      systemd.services.comfyui.environment.HIP_VISIBLE_DEVICES = "0";
    };
}

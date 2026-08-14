# nixpkgs' comfyui wires its python env for CUDA/CPU, so re-fix the package
# set with ROCm torch (prebuilt on cache.nixos.org) for the AMD GPU.
_: {
  flake.nixosModules.comfyui =
    { lib, pkgs, ... }:
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
      systemd.services.comfyui = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        # Hide the Ryzen iGPU from HIP so ComfyUI only sees the dGPU
        environment.HIP_VISIBLE_DEVICES = "0";

        serviceConfig = {
          ExecStart = "${lib.getExe pkgsWithRocmTorch.comfyui} --listen 127.0.0.1 --port 8188";

          # Models and outputs live in ~soft/.local/share/comfyui
          User = "soft";
          Group = "users";

          Restart = "on-failure";
        };
      };
    };
}

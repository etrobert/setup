{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.nix-dead-packages = self.lib.wrapPackage pkgs {
        package = pkgs.buildGoModule {
          pname = "nix-dead-packages";
          version = "0";
          src = ./.;
          # No dependencies, so nothing to vendor.
          vendorHash = null;
          meta.mainProgram = "nix-dead-packages";
        };
        runtimeInputs = with pkgs; [
          git
          nix
        ];
      };
    };
}

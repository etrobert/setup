{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.nix-dead-packages = self.lib.wrapPackage pkgs {
        package = pkgs.writers.writeRustBin "nix-dead-packages" {
          rustcArgs = [
            "--edition"
            "2021"
          ];
        } ./nix-dead-packages.rs;
        runtimeInputs = with pkgs; [
          git
          nix
        ];
        platforms = lib.platforms.all;
      };
    };
}

{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        save-displays-nu = self.lib.wrapPackage pkgs {
          package = pkgs.writers.writeNuBin "save-displays-nu" (builtins.readFile ./save-displays.nu);
          # mkdir and mv are nushell builtins, so only niri comes from outside.
          runtimeInputs = [ pkgs.niri ];
          platforms = lib.platforms.linux;
        };
      };
    };
}

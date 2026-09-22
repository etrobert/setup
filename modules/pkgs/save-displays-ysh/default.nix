{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        save-displays-ysh = self.lib.wrapPackage pkgs {
          package = pkgs.writeScriptBin "save-displays-ysh" ''
            #!${lib.getExe' pkgs.oils-for-unix "ysh"}
            ${builtins.readFile ./save-displays.ysh}
          '';
          runtimeInputs = with pkgs; [
            coreutils # provides mkdir, mv
            niri
          ];
          platforms = lib.platforms.linux;
        };
      };
    };
}

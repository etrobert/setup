{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        save-displays = pkgs.writeShellApplication {
          name = "save-displays";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = with pkgs; [
            coreutils # provides mkdir, mv
            jq
            niri # provides niri msg
          ];
          inheritPath = false;
          text = builtins.readFile ./save-displays.sh;
        };
      };
    };
}

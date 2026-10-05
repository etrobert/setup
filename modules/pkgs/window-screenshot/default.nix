{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = self.lib.onlySupported {
        window-screenshot = pkgs.writeShellApplication {
          name = "window-screenshot";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = with pkgs; [
            coreutils
            imagemagick
            jq
            niri
            wl-clipboard
          ];
          inheritPath = false;
          text = builtins.readFile ./window-screenshot.sh;
        };
      };
    };
}

{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages = self.lib.onlySupported {
        open-url =
          let
            script = pkgs.writeShellApplication {
              name = "open-url";
              runtimeInputs = [
                pkgs.jq
                self'.packages.niri-wrapped
                self'.packages.zen-browser-wrapped
              ];
              inheritPath = false;
              text = builtins.readFile ./open-url;
            };

            desktopItem = pkgs.makeDesktopItem {
              name = "open-url";
              exec = "open-url %u";
              desktopName = "Open URL";
              noDisplay = true;
              mimeTypes = [
                "x-scheme-handler/http"
                "x-scheme-handler/https"
                "text/html"
              ];
            };
          in
          pkgs.symlinkJoin {
            meta.platforms = lib.platforms.linux;
            name = "open-url";
            paths = [
              script
              desktopItem
            ];
          };
      };
    };
}

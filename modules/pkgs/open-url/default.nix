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
          assert lib.assertMsg (lib.versions.majorMinor pkgs.niri.version == "26.04")
            ''niri ${pkgs.niri.version} has the on-xdg-activate window rule — drop open-url, point the handlers in nixos-workstation.nix at zen.desktop and add `window-rule { match app-id="zen"; on-xdg-activate "focus" }`'';
          let
            script = pkgs.writeShellApplication {
              name = "open-url";
              runtimeInputs = [
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

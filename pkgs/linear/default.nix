{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = self.lib.onlySupported {
        # Linear ships desktop apps for macOS and Windows only, so run the web app in
        # a Chromium app window.
        linear =
          let
            script = pkgs.writeShellApplication {
              name = "linear";
              runtimeInputs = [ pkgs.chromium ];
              inheritPath = false;
              text = ''
                exec chromium --app=https://linear.app/ "$@"
              '';
            };

            desktopItem = pkgs.makeDesktopItem {
              name = "linear";
              exec = "linear";
              desktopName = "Linear";
              icon = "${./icon.svg}";
              categories = [ "Development" ];
              # Chromium derives an app window's app_id from the --app URL's host.
              startupWMClass = "chrome-linear.app__-Default";
            };
          in
          pkgs.symlinkJoin {
            meta.platforms = lib.platforms.linux;
            name = "linear";
            paths = [
              script
              desktopItem
            ];
          };
      };
    };
}

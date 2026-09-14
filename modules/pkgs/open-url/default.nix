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
            niri = lib.getExe self'.packages.niri-wrapped;
            zen = lib.getExe self'.packages.zen-browser-wrapped;
            niriVersion = lib.versions.majorMinor pkgs.niri.version;
          in
          assert lib.assertMsg (niriVersion == "26.04") ''
            niri ${niriVersion} has the on-xdg-activate window rule: drop
            open-url, point the handlers in nixos-workstation.nix at
            zen.desktop and add
            `window-rule { match app-id="zen"; on-xdg-activate "focus" }`
          '';
          (pkgs.makeDesktopItem {
            name = "open-url";
            # niri mints an activation token for what it spawns, so Zen gets
            # focus; a plain launch from another app only marks the window
            # urgent.
            exec = "${niri} msg action spawn -- ${zen} %u";
            desktopName = "Open URL";
            noDisplay = true;
            mimeTypes = [
              "x-scheme-handler/http"
              "x-scheme-handler/https"
              "text/html"
            ];
          }).overrideAttrs
            { meta.platforms = lib.platforms.linux; };
      };
    };
}

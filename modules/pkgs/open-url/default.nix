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
          (pkgs.makeDesktopItem {
            name = "open-url";
            # niri mints an activation token for what it spawns, so Zen gets
            # focus; a plain launch from another app only marks the window urgent.
            exec = "${lib.getExe self'.packages.niri-wrapped} msg action spawn -- ${lib.getExe self'.packages.zen-browser-wrapped} %u";
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

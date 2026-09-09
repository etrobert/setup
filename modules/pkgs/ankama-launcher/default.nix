{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      # Vendored from nixpkgs, which is stuck on 3.14.14: it pins the AppImage
      # through a Wayback Machine snapshot and Ankama's CDN now blocks the
      # archiver (NixOS/nixpkgs#474164). Running a launcher older than what
      # Ankama serves makes its auto-updater fire, and self-update cannot work
      # from the store — startup dies on "APPIMAGE env is not defined". The URL
      # carries no version, so `hash` is what pins the release: when Ankama
      # ships the next one this stops fetching until both are bumped.
      packages = self.lib.onlySupported {
        ankama-launcher =
          let
            pname = "ankama-launcher";
            version = "3.15.5";

            src = pkgs.fetchurl {
              url = "https://launcher.cdn.ankama.com/installers/production/Ankama%20Launcher-Setup-x86_64.AppImage";
              hash = "sha256-6q0kAFXtrnud8rvxN6o6mIiwklzjZYAopf1MlS3ODbU=";
            };

            appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
          in
          assert lib.assertMsg (lib.versionOlder pkgs.ankama-launcher.version version)
            "nixpkgs ankama-launcher reached ${pkgs.ankama-launcher.version} — drop modules/pkgs/ankama-launcher and install pkgs.ankama-launcher instead";
          pkgs.appimageTools.wrapType2 {
            inherit pname version src;
            extraPkgs = pkgs: [ pkgs.wine ];

            extraInstallCommands = ''
              install -m 444 -D ${appimageContents}/zaap.desktop $out/share/applications/ankama-launcher.desktop
              sed -i 's/.*Exec.*/Exec=ankama-launcher/' $out/share/applications/ankama-launcher.desktop
              install -m 444 -D ${appimageContents}/zaap.png $out/share/icons/hicolor/256x256/apps/zaap.png
            '';

            meta = {
              license = lib.licenses.unfree;
              mainProgram = "ankama-launcher";
              platforms = [ "x86_64-linux" ];
            };
          };
      };
    };
}

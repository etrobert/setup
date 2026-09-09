{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      # Vendored because nixpkgs is behind at 3.14.14. Running a launcher older
      # than what Ankama serves makes its auto-updater fire, and it cannot
      # rewrite an AppImage that is an extracted store path: it raises
      # "APPIMAGE env is not defined" and logs a fatal unhandled rejection.
      #
      # The URL carries no version and always serves the current release, so
      # `hash` stops matching once Ankama ships one. That is deliberate: this
      # package must track their latest anyway, and a hash mismatch says so at
      # the moment it becomes true. nixpkgs pins a Wayback snapshot instead
      # because its users have cold stores; here that would only buy a build
      # of a release the launcher already refuses to run.
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

            extraInstallCommands = # bash
              ''
                # The URL carries no version, so `version` is only a claim about
                # whatever `hash` pinned; the AppImage itself states the truth.
                archive_version=$(grep --only-matching --perl-regexp \
                  '(?<=X-AppImage-Version=).*' ${appimageContents}/zaap.desktop)
                if [[ "$archive_version" != "${version}"* ]]; then
                  echo "version is ${version} but the AppImage is $archive_version"
                  exit 1
                fi

                install -m 444 -D ${appimageContents}/zaap.desktop $out/share/applications/ankama-launcher.desktop
                sed -i 's/.*Exec.*/Exec=ankama-launcher/' $out/share/applications/ankama-launcher.desktop
                install -m 444 -D ${appimageContents}/zaap.png $out/share/icons/hicolor/256x256/apps/zaap.png
              '';

            meta = {
              description = "Ankama Launcher";
              homepage = "https://www.ankama.com/en/launcher";
              license = lib.licenses.unfree;
              mainProgram = "ankama-launcher";
              sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
              platforms = [ "x86_64-linux" ];
            };
          };
      };
    };
}

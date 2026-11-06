{ self, ... }:
{
  flake.nixosModules.ankama-launcher =
    { pkgs, ... }:
    let
      # Run from a writable copy so it can self-update: a pinned store copy crashes once Ankama ships a newer release.
      launcher = pkgs.writeShellApplication {
        name = "ankama-launcher";
        inheritPath = false;
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          appimage="''${XDG_DATA_HOME:-$HOME/.local/share}/ankama-launcher/ankama-launcher.AppImage"
          if [ ! -e "$appimage" ]; then
            install -D --mode 755 ${pkgs.ankama-launcher.src} "$appimage"
          fi
          exec "$appimage" "$@"
        '';
      };
    in
    {
      # Dofus 3 aborts on startup without it.
      imports = [ self.nixosModules.xwayland-client-list ];

      # The updater restarts the launcher by executing the AppImage directly.
      programs.appimage = {
        enable = true;
        binfmt = true;
      };

      environment.systemPackages = [
        launcher
        (pkgs.makeDesktopItem {
          name = "ankama-launcher";
          desktopName = "Ankama Launcher";
          exec = "ankama-launcher %U";
          startupWMClass = "Ankama Launcher";
          mimeTypes = [ "x-scheme-handler/zaap" ];
          categories = [ "Game" ];
        })
      ];
    };
}

_:
let
  wallpaper = "file://${../../assets/saint-levant.jpg}";
in
{
  flake.nixosModules.gnome =
    { pkgs, ... }:
    {
      # Registers a GNOME entry in services.displayManager.sessionPackages, which
      # is what puts it in the login prompt's session list. No gdm: it does not
      # pull one in, so greetd stays the display manager.
      services.desktopManager.gnome.enable = true;

      environment.systemPackages = with pkgs.gnomeExtensions; [
        astra-monitor # CPU/GPU/RAM/net readouts in the top bar
        paperwm # scrollable tiling, niri's ancestor
      ];

      # GNOME loads an extension only if its UUID is listed here; installing the
      # package is not enough.
      programs.dconf.profiles.user.databases = [
        {
          settings."org/gnome/shell".enabled-extensions = [
            "paperwm@paperwm.github.com"
            "monitor@astraext.github.io"
          ];

          # Both variants: picture-uri-dark defaults to GNOME's own dark Adwaita,
          # so leaving it out shows the stock wallpaper whenever darkman is dark.
          settings."org/gnome/desktop/background" = {
            picture-uri = wallpaper;
            picture-uri-dark = wallpaper;
          };
        }
      ];
    };
}

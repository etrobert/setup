_: {
  flake.nixosModules.fileManager =
    { pkgs, ... }:
    {
      # GVFS backs Nautilus's trash and removable-media mounting.
      services.gvfs.enable = true;

      # Nautilus thumbnails come from gnome-desktop's factory, which runs the
      # .thumbnailer programs it finds on XDG_DATA_DIRS. niri has no desktop
      # environment to supply them, so each format needs its provider here.
      environment.systemPackages = [
        pkgs.nautilus
        pkgs.ffmpegthumbnailer # video
        pkgs.gdk-pixbuf # raster images
        pkgs.librsvg # svg
      ];
    };
}

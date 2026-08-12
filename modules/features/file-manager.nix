_: {
  flake.nixosModules.fileManager =
    { pkgs, ... }:
    {
      # Nautilus's sidebar: the gvfs-daemon backends (smb://, sftp://,
      # trash://), the volume monitors that surface USB drives and phones,
      # and gvfs-metadata, which stores per-file emblems and sort order.
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

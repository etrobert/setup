_: {
  flake.nixosModules.fileManager =
    {
      self,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) thumbnailer-3mf thumbnailer-html;
    in
    {
      services = {
        # Nautilus's sidebar: the gvfs-daemon backends (smb://, sftp://,
        # trash://), the volume monitors that surface USB drives and phones,
        # and gvfs-metadata, which stores per-file emblems and sort order.
        gvfs.enable = true;

        # Nautilus searches by querying a Tracker3 index over D-Bus. tinysparql
        # is the store, localsearch the indexer that fills it; without both,
        # search falls back to walking the tree.
        gnome = {
          tinysparql.enable = true;
          localsearch.enable = true;
        };
      };

      # Nautilus thumbnails come from gnome-desktop's factory, which runs the
      # .thumbnailer programs it finds on XDG_DATA_DIRS. niri has no desktop
      # environment to supply them, so each format needs its provider here.
      environment.systemPackages = [
        pkgs.nautilus
        pkgs.ffmpegthumbnailer # video
        pkgs.gdk-pixbuf # raster images
        pkgs.librsvg # svg
        thumbnailer-3mf
        thumbnailer-html
      ];
    };
}

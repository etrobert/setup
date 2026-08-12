_: {
  flake.nixosModules.fileManager =
    {
      self,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) thumbnailer-3mf;
    in
    {
      services = {
        # GVFS backs Nautilus's trash and removable-media mounting.
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
      ];
    };
}

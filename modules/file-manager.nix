_: {
  # Thunar file manager with video/image cover thumbnails. niri has no desktop
  # environment and therefore no thumbnailer service, so a file manager on its
  # own shows blank icons for videos. Tumbler is the missing D-Bus thumbnailer.
  flake.nixosModules.fileManager = {
    # D-Bus thumbnailer service. nixpkgs builds tumbler with ffmpegthumbnailer,
    # so it generates video cover thumbnails (cached in ~/.cache/thumbnails) for
    # any file manager that requests them over D-Bus.
    services.tumbler.enable = true;

    # GVFS backs Thunar's trash and removable-media mounting.
    services.gvfs.enable = true;

    # File manager that requests thumbnails from tumbler over D-Bus.
    programs.thunar.enable = true;
  };
}

_: {
  # Opt-in: follows the currently playing track's MPRIS art and sets it as the
  # desktop wallpaper via awww. Not imported anywhere at the moment — add
  # self.nixosModules.albumArtWallpaper to a host's imports to enable it.
  flake.nixosModules.albumArtWallpaper =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      systemd.user.services.album-art-wallpaper = {
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig.ExecStart = lib.getExe self.packages.${system}.album-art-wallpaper;
      };
    };
}

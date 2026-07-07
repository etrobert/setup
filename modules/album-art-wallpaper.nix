_: {
  # Opt-in: follows the currently playing track's MPRIS art and sets it as the
  # desktop wallpaper via awww. Not imported anywhere at the moment — add
  # self.nixosModules.albumArtWallpaper to a host's imports to enable it.
  flake.nixosModules.albumArtWallpaper =
    {
      lib,
      pkgs,
      ...
    }:
    let
      album-art-wallpaper = pkgs.writeShellApplication {
        name = "album-art-wallpaper";

        runtimeInputs = [
          pkgs.playerctl
          pkgs.curl
          pkgs.awww
        ];

        text = ''
          playerctl --follow metadata --format '{{mpris:artUrl}}' | while read -r url; do
            [ -z "$url" ] && continue
            curl -sL "$url" -o /tmp/albumart.jpg
            awww img /tmp/albumart.jpg
          done
        '';
      };
    in
    {
      systemd.user.services.album-art-wallpaper = {
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig.ExecStart = lib.getExe album-art-wallpaper;
      };
    };
}

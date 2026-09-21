_: {
  flake.nixosModules.navidrome =
    { config, ... }:
    {
      services.navidrome = {
        enable = true;
        settings.MusicFolder = "/tank/media/music";
      };

      # The sandbox binds MusicFolder at start; before the mount that is an empty dir.
      systemd.services.navidrome.unitConfig.RequiresMountsFor = [
        config.services.navidrome.settings.MusicFolder
      ];

      services.tsnsrv.services.music.toURL =
        "http://127.0.0.1:${toString config.services.navidrome.settings.Port}";
    };
}

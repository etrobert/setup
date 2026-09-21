_: {
  flake.nixosModules.navidrome =
    { config, lib, ... }:
    {
      services.navidrome = {
        enable = true;
        settings = {
          Address = "0.0.0.0";
          MusicFolder = "/tank/media/music";
        };
      };

      systemd.services.navidrome = {
        serviceConfig.ProtectHome = lib.mkForce "tmpfs";
        # The sandbox binds MusicFolder at start; before the mount that is an empty dir.
        unitConfig.RequiresMountsFor = [ config.services.navidrome.settings.MusicFolder ];
      };

      services.tsnsrv.services.music.toURL =
        "http://127.0.0.1:${toString config.services.navidrome.settings.Port}";
    };
}

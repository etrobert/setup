_: {
  flake.nixosModules.navidrome =
    { config, ... }:
    {
      services = {
        navidrome = {
          enable = true;
          settings = {
            MusicFolder = "/tank/media/music";
            # Deleted files linger forever otherwise. Not "always": an incremental
            # scan of an unmounted library would purge everything.
            Scanner.PurgeMissing = "full";
          };
        };

        tsnsrv.services.music.toURL = "http://127.0.0.1:${toString config.services.navidrome.settings.Port}";

        # Navidrome's own login is the gate.
        caddy.virtualHosts."music.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:${toString config.services.navidrome.settings.Port}
        '';
      };

      # The sandbox binds MusicFolder at start; before the mount that is an empty dir.
      systemd.services.navidrome.unitConfig.RequiresMountsFor = [
        config.services.navidrome.settings.MusicFolder
      ];
    };
}

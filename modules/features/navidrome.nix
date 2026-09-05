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

      systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "tmpfs";

      # `music/` on the tailnet; tailnet-services.nix owns the tsnsrv defaults.
      services.tsnsrv.services.music = {
        toURL = "http://127.0.0.1:${toString config.services.navidrome.settings.Port}";
        plaintext = true;
      };
    };
}

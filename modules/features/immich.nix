_: {
  flake.nixosModules.immich =
    { config, ... }:
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.immich.port ];

      services.immich = {
        enable = true;
        host = "0.0.0.0";
        mediaLocation = "/tank/photos";

        # The default, [ ], sets PrivateDevices=true, which hides /dev/dri from
        # the unit. ffmpeg.accel below then throws before the transcode even
        # starts, with no software fallback, so the two go together.
        accelerationDevices = [ "/dev/dri/renderD128" ];

        settings = {
          backup.database.enabled = true;
          ffmpeg.accel = "vaapi";
          newVersionCheck.enabled = false;
          storageTemplate.enabled = true;
        };
      };

      systemd.services.immich-server.unitConfig.RequiresMountsFor = [
        config.services.immich.mediaLocation
      ];
    };
}

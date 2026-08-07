# Self-hosted photo and video library, backed by the tank/photos dataset and
# reachable over Tailscale only.
_: {
  flake.nixosModules.immich =
    { config, ... }:
    {
      # immich listens on every interface; the firewall is what keeps it
      # reachable over Tailscale only.
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

          # Turning this on later runs a migration that rewrites the path of
          # every asset already stored.
          storageTemplate.enabled = true;
        };
      };

      # mediaLocation reaches the unit as an environment variable rather than a
      # path-taking directive, so systemd derives no mount dependency from it.
      systemd.services.immich-server.unitConfig.RequiresMountsFor = [
        config.services.immich.mediaLocation
      ];
    };
}

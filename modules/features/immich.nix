_: {
  flake.nixosModules.immich =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Some HDR videos wedge ffmpeg in Immich's VAAPI + software-tonemap
      # fallback: it spins on CPU forever instead of exiting. Immich only walks
      # on to its software-only rung when ffmpeg *fails*, and videoConversion
      # runs at concurrency 1, so one hang parks the whole video queue (and any
      # restart of this unit). Time-boxing turns the hang into that failure.
      ffmpeg-timeboxed = pkgs.writeShellApplication {
        name = "ffmpeg";
        inheritPath = false;

        runtimeInputs = [ pkgs.coreutils ];

        text = ''
          exec timeout --signal=KILL 10m ${lib.getExe pkgs.jellyfin-ffmpeg} "$@"
        '';
      };
    in
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ config.services.immich.port ];

      services.immich = {
        enable = true;
        host = "0.0.0.0";
        mediaLocation = "/tank/photos";

        environment.IMMICH_LOG_LEVEL = "verbose";

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

      systemd.services.immich-server = {
        unitConfig.RequiresMountsFor = [ config.services.immich.mediaLocation ];

        # fluent-ffmpeg prefers this over the ffmpeg it finds on PATH.
        environment.FFMPEG_PATH = lib.getExe ffmpeg-timeboxed;
      };
    };
}

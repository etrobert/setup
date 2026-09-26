{ self, ... }:
{
  perSystem =
    { self', ... }:
    {
      packages.auto-brightness = self'.legacyPackages.writers.writeBunBin "auto-brightness" (
        builtins.readFile ./auto-brightness.ts
      );
    };

  flake.nixosModules.autoBrightness =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.autoBrightness;
      auto-brightness = self.packages.${pkgs.stdenv.hostPlatform.system}.auto-brightness;
    in
    {
      options.autoBrightness = {
        day = lib.mkOption {
          type = lib.types.ints.between 0 100;
          description = "Screen brightness percentage until 16:00.";
        };
        night = lib.mkOption {
          type = lib.types.ints.between 0 100;
          description = "Screen brightness percentage from 23:00 to 05:00.";
        };
      };

      config.systemd.user = {
        services.auto-brightness = {
          description = "Set screen brightness for the time of day";
          path = [ config.programs.noctalia.package ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe auto-brightness} ${toString cfg.day} ${toString cfg.night}";
          };
        };

        timers.auto-brightness = {
          description = "Schedule the screen brightness update";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          timerConfig = {
            OnCalendar = "*:0/15";
            # A first run once noctalia is up after login.
            OnActiveSec = "10s";
          };
        };
      };
    };
}

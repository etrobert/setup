{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.auto-brightness = pkgs.buildNpmPackage {
        pname = "auto-brightness";
        version = "0.0.0";
        src = ./.;
        npmDeps = pkgs.importNpmLock { npmRoot = ./.; };
        npmConfigHook = pkgs.importNpmLock.npmConfigHook;
        # npm's typescript would fetch its compiler for all 20 platforms
        nativeBuildInputs = [ pkgs.typescript ];
        # zx runs commands through bash
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          (lib.makeBinPath [ pkgs.bashNonInteractive ])
        ];
        meta.mainProgram = "auto-brightness";
      };
    };

  flake.nixosModules.auto-brightness =
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
          description = "Screen brightness percentage with the sun above 6°.";
        };
        night = lib.mkOption {
          type = lib.types.ints.between 0 100;
          description = "Screen brightness percentage with the sun below -6°.";
        };
      };

      config.systemd.user = {
        services.auto-brightness = {
          description = "Set screen brightness for the height of the sun";
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

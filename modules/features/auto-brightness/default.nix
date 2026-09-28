{ self, ... }:
{
  perSystem =
    { inputs', ... }:
    let
      bun2nix = inputs'.bun2nix.packages.default;
    in
    {
      packages.auto-brightness = bun2nix.mkDerivation {
        pname = "auto-brightness";
        version = "0.0.0";
        src = ./.;
        module = "auto-brightness.ts";
        bunDeps = bun2nix.fetchBunDeps { bunNix = ./_bun.nix; };
        # Bytecode compiles to CommonJS, which has no top-level await
        bunCompileToBytecode = false;
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

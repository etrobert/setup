{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.auto-brightness =
        let
          nodeModules = pkgs.importNpmLock.buildNodeModules {
            npmRoot = ./.;
            inherit (pkgs) nodejs;
          };
        in
        pkgs.runCommand "auto-brightness"
          {
            # From nixpkgs: npm's typescript and esbuild would fetch a binary for every platform
            nativeBuildInputs = [
              pkgs.typescript
              pkgs.esbuild
              pkgs.makeBinaryWrapper
            ];
            meta.mainProgram = "auto-brightness";
          }
          /* bash */ ''
            cp ${./auto-brightness.ts} auto-brightness.ts
            cp ${./tsconfig.json} tsconfig.json
            cp ${./package.json} package.json
            ln --symbolic ${nodeModules}/node_modules node_modules
            tsc
            # Bundled CommonJS, like zx, calls require, which an ES module lacks
            # --preserve-symlinks: the bundle's path comments would otherwise pin node_modules at runtime
            esbuild auto-brightness.ts --bundle --platform=node --format=esm --preserve-symlinks \
              --banner:js='import { createRequire as __createRequire } from "node:module"; const require = __createRequire(import.meta.url);' \
              --outfile=$out/lib/auto-brightness.mjs
            # zx runs commands through bash
            makeWrapper ${lib.getExe pkgs.nodejs} $out/bin/auto-brightness \
              --add-flags $out/lib/auto-brightness.mjs \
              --prefix PATH : ${lib.makeBinPath [ pkgs.bashNonInteractive ]}
          '';
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

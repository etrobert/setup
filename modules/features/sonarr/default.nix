{ self, ... }:
{
  flake.nixosModules.sonarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      port = config.services.sonarr.settings.server.port;

      sonarr-setup =
        self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.writers.writeNuBin "sonarr-setup"
          {
            makeWrapperArgs = [
              "--prefix"
              "PATH"
              ":"
              (lib.makeBinPath [ self.packages.${pkgs.stdenv.hostPlatform.system}.recyclarr-wrapped ])
            ];
          }
          (builtins.readFile ./setup.nu);
    in
    {
      services = {
        sonarr = {
          enable = true;

          # soft:users owns the library and the landing zone; imports write into both.
          user = "soft";
          group = "users";

          settings = {
            # Sonarr defaults to *; only tsnsrv on loopback should reach it.
            server.bindaddress = "127.0.0.1";

            # No login: the tailnet is the only access control.
            # Not the default None: the UI then locks itself behind a setup modal that refuses None.
            # Capitalised: Sonarr parses the value as a C# enum, case-sensitively.
            auth.method = "External";
          };
        };

        tsnsrv.services.sonarr.toURL = "http://127.0.0.1:${toString port}";
      };

      systemd.services = {
        sonarr = {
          # The library watcher is created once at start and never retried; before the mount it dies.
          unitConfig.RequiresMountsFor = [ "/tank/media" ];

          # No login on the tailnet, so a UI click must not reach the rest of what soft owns.
          serviceConfig = {
            ProtectSystem = "strict";
            ProtectHome = true;
            # SQLite spills statement journals to /tmp, read-only under strict.
            PrivateTmp = true;
            # One mount for tv/ and torrents/: a hardlink across two bind mounts fails with EXDEV.
            ReadWritePaths = [ "/tank/media" ];
            InaccessiblePaths = [ "/run/agenix.d" ];
          };
        };

        sonarr-setup = {
          description = "Declare Sonarr's indexer, download client, library, quality profile and notification";
          after = [ "sonarr.service" ];
          wantedBy = [ "sonarr.service" ];

          serviceConfig = {
            Type = "oneshot";
            # Stays active so switch-to-configuration reruns it when setup.nu changes.
            RemainAfterExit = true;
            ExecStart = "${lib.getExe sonarr-setup} http://127.0.0.1:${toString port} ${config.age.secrets.c411-api-key.path} ${./recyclarr.yml}";
            # soft owns the c411 key.
            User = "soft";
            # Recyclarr's record of what it created.
            StateDirectory = "recyclarr";
            Environment = "RECYCLARR_CONFIG_DIR=%S/recyclarr";
            # Oneshots have no start timeout by default; the wait loops would hang silently.
            TimeoutStartSec = "5min";
          };
        };
      };
    };
}

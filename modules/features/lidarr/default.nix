{ self, ... }:
{
  flake.nixosModules.lidarr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      port = config.services.lidarr.settings.server.port;
      packages = self.packages.${pkgs.stdenv.hostPlatform.system};

      lidarr-setup =
        self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.writers.writeNuBin "lidarr-setup" { }
          (builtins.readFile ./setup.nu);
    in
    {
      services = {
        lidarr = {
          enable = true;
          package = packages.lidarr-develop;

          # soft:users owns the library and the landing zone; imports write into both.
          user = "soft";
          group = "users";

          settings = {
            # Lidarr defaults to *; only tsnsrv on loopback should reach it.
            server.bindaddress = "127.0.0.1";

            # No login: the tailnet is the only access control.
            # Not the default None: the UI then locks itself behind a setup modal that refuses None.
            # Capitalised: Lidarr parses the value as a C# enum, case-sensitively.
            auth.method = "External";
          };
        };

        tsnsrv.services.lidarr.toURL = "http://127.0.0.1:${toString port}";
      };

      systemd.services = {
        lidarr = {
          # fpcalc fingerprints badly tagged files; the package does not ship it.
          path = [ pkgs.chromaprint ];

          # The library watcher is created once at start and never retried; before the mount it dies.
          unitConfig.RequiresMountsFor = [ "/tank/media" ];

          # Where System > Plugins would install it; copied, not linked: Tubifarry writes settings.resx beside itself.
          preStart = ''
            mkdir --parents ${config.services.lidarr.dataDir}/plugins/TypNull/Tubifarry
            cp --recursive --no-preserve=mode ${packages.tubifarry}/. ${config.services.lidarr.dataDir}/plugins/TypNull/Tubifarry
          '';

          # No login on the tailnet, so a UI click must not reach the rest of what soft owns.
          serviceConfig = {
            ProtectSystem = "strict";
            ProtectHome = true;
            # SQLite spills statement journals to /tmp, read-only under strict.
            PrivateTmp = true;
            # One mount for music/ and torrents/: a hardlink across two bind mounts fails with EXDEV.
            ReadWritePaths = [
              config.services.lidarr.dataDir
              "/tank/media"
            ];
            InaccessiblePaths = [ "/run/agenix.d" ];
          };
        };

        lidarr-setup = {
          description = "Declare Lidarr's indexer, download client, library and notification";
          after = [ "lidarr.service" ];
          wantedBy = [ "lidarr.service" ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe lidarr-setup} http://127.0.0.1:${toString port} ${config.age.secrets.c411-api-key.path}";
            # soft owns the c411 key.
            User = "soft";
            # Oneshots have no start timeout by default; the wait loops would hang silently.
            TimeoutStartSec = "5min";
          };
        };
      };
    };
}

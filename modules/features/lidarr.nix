_: {
  flake.nixosModules.lidarr =
    { config, pkgs, ... }:
    {
      services = {
        lidarr = {
          enable = true;

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

        tsnsrv.services.lidarr.toURL = "http://127.0.0.1:${toString config.services.lidarr.settings.server.port}";
      };

      systemd.services.lidarr = {
        # fpcalc fingerprints badly tagged files; the package does not ship it.
        path = [ pkgs.chromaprint ];

        # The library watcher is created once at start and never retried; before the mount it dies.
        unitConfig.RequiresMountsFor = [ "/tank/media" ];

        # No login on the tailnet, so a UI click must not reach the rest of what soft owns.
        serviceConfig = {
          ProtectSystem = "strict";
          ProtectHome = true;
          # SQLite spills statement journals to /tmp, read-only under strict.
          PrivateTmp = true;
          ReadWritePaths = [
            config.services.lidarr.dataDir
            "/tank/media/music"
            "/tank/media/torrents"
          ];
          InaccessiblePaths = [ "/run/agenix.d" ];
        };
      };
    };
}

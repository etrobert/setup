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
      ntfyPort = self.nixosConfigurations.tower.config.ports.ntfy;

      lidarr-setup =
        self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.writers.writeNuBin "lidarr-setup" { }
          (builtins.readFile ./setup.nu);
    in
    {
      services = {
        lidarr = {
          enable = true;

          # soft:users owns the shared library.
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

      age.secrets.c411-api-key = {
        file = ../../../secrets/c411-api-key.age;
        owner = "soft";
      };

      systemd.services = {
        lidarr = {
          # fpcalc fingerprints badly tagged files; the package does not ship it.
          path = [ pkgs.chromaprint ];

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
            ReadWritePaths = [
              config.services.lidarr.dataDir
              "/storage/music"
            ];
            InaccessiblePaths = [ "/run/agenix.d" ];
            # The library is shared: everyone in users must be able to update what Lidarr writes.
            UMask = "0002";
          };
        };

        lidarr-setup = {
          description = "Declare Lidarr's indexer, download client, library and notification";
          # Testing the notification needs DNS, which is MagicDNS.
          after = [
            "lidarr.service"
            "tailscaled-autoconnect.service"
          ];
          wantedBy = [ "lidarr.service" ];
          # Longer than 5 attempts at TimeoutStartSec, so the burst always caps the retries.
          startLimitIntervalSec = 1800;

          serviceConfig = {
            Type = "oneshot";
            # Tailscale runs before it has fetched its peers, so MagicDNS names fail for a few seconds.
            Restart = "on-failure";
            RestartSec = "5s";
            # direct: the ntfy OnFailure= alert fires only once the retries run out.
            RestartMode = "direct";
            ExecStart = lib.escapeShellArgs [
              (lib.getExe lidarr-setup)
              "http://127.0.0.1:${toString port}"
              config.age.secrets.c411-api-key.path
              "https://soulseek.etiennerobert.com"
              # Bind-mounted from the container's host, which runs slskd.
              "/run/secrets/slskd/api-key"
              "http://tower:${toString ntfyPort}"
            ];
            # soft owns the c411 and slskd keys.
            User = "soft";
            # Oneshots have no start timeout by default; the wait loops would hang silently.
            TimeoutStartSec = "5min";
          };
        };
      };
    };
}

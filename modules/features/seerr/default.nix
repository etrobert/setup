{ self, ... }:
{
  flake.nixosModules.seerr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      port = config.services.seerr.port;

      seerr-setup =
        self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.writers.writeNuBin "seerr-setup" { }
          (builtins.readFile ./setup.nu);

      url = port: "http://127.0.0.1:${toString port}";
    in
    {
      services = {
        seerr = {
          enable = true;
          stateRevision = 1;
        };

        tsnsrv.services.seerr.toURL = url port;
      };

      systemd.services = {
        # Seerr defaults to all interfaces; Jellyfin's plugins and tsnsrv reach it on loopback.
        seerr.environment.HOST = "127.0.0.1";

        seerr-setup = {
          description = "Connect Seerr to Jellyfin, Radarr and Sonarr, and Jellyfin's plugins to Seerr";
          after = [
            "seerr.service"
            "jellyfin.service"
            "radarr-setup.service"
            "sonarr-setup.service"
          ];
          wants = [
            "radarr-setup.service"
            "sonarr-setup.service"
          ];
          wantedBy = [ "seerr.service" ];

          serviceConfig = {
            Type = "oneshot";
            # Stays active so switch-to-configuration reruns it when setup.nu changes.
            RemainAfterExit = true;
            DynamicUser = true;
            LoadCredential = [ "jellyfin-api-key:${config.age.secrets.jellyfin-api-key.path}" ];
            ExecStart = lib.escapeShellArgs [
              (lib.getExe seerr-setup)
              (url port)
              (url 8096)
              (url config.services.radarr.settings.server.port)
              (url config.services.sonarr.settings.server.port)
            ];
            # Oneshots have no start timeout by default; the wait loops would hang silently.
            TimeoutStartSec = "5min";
          };
        };
      };
    };
}

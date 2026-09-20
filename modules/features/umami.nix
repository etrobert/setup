_: {
  flake.nixosModules.umami =
    { config, ... }:
    {
      services = {
        umami = {
          enable = true;
          createPostgresqlDatabase = true;
          settings = {
            APP_SECRET_FILE = config.age.secrets.umami-app-secret.path;
            DISABLE_TELEMETRY = true;
            # creatures-server holds 3000
            PORT = 3001;
          };
        };

        caddy.virtualHosts."umami.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:${toString config.services.umami.settings.PORT}
        '';
      };

      age.secrets.umami-app-secret.file = ../../secrets/umami-app-secret.age;
    };
}

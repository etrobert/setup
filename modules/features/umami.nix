_: {
  flake.nixosModules.umami =
    { config, ... }:
    {
      ports.umami = "auto";

      services = {
        umami = {
          enable = true;
          createPostgresqlDatabase = true;
          settings = {
            APP_SECRET_FILE = config.age.secrets.umami-app-secret.path;
            DISABLE_TELEMETRY = true;
            PORT = config.ports.umami;
          };
        };

        caddy.virtualHosts."umami.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:${toString config.services.umami.settings.PORT}
        '';
      };

      age.secrets.umami-app-secret.file = ../../secrets/umami-app-secret.age;
    };
}

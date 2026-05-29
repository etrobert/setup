_: {
  flake.nixosModules.umami =
    { config, ... }:
    {
      services.umami = {
        enable = true;
        createPostgresqlDatabase = true;
        settings = {
          APP_SECRET_FILE = config.age.secrets.umami-app-secret.path;
          DISABLE_TELEMETRY = true;
          # creatures already occupies port 3000 on tower.
          PORT = 3001;
        };
      };

      age.secrets.umami-app-secret.file = ../secrets/umami-app-secret.age;
    };
}

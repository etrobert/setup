_: {
  flake.nixosModules.umami =
    { config, ... }:
    {
      services.umami = {
        enable = true;
        createPostgresqlDatabase = true;
        settings = {
          # Reuses the Railway APP_SECRET so JWT/session hashing stays
          # consistent after we cut over to this instance. `_FILE` form
          # keeps the value out of the world-readable Nix store.
          APP_SECRET_FILE = config.age.secrets.umami-app-secret.path;
          DISABLE_TELEMETRY = true;
          # creatures already occupies port 3000 on tower.
          PORT = 3001;
        };
      };

      age.secrets.umami-app-secret.file = ../secrets/umami-app-secret.age;
    };
}

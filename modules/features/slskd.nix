{
  flake.nixosModules.slskd =
    { config, lib, ... }:
    {
      age.secrets.slskd-env.file = ../../secrets/slskd-env.age;

      services = {
        slskd = {
          enable = true;
          environmentFile = config.age.secrets.slskd-env.path;
          openFirewall = true;

          settings = {
            # Share back what we fetched, the way transmission seeds.
            shares = {
              # slskd's default downloads directory.
              directories = [ "/var/lib/slskd/downloads" ];
              # Without it the share never picks up new downloads.
              cache.retention = 60;
            };

            retention.files.complete = 72 * 60;

            web = {
              # Only tsnsrv on loopback should reach it.
              ip_address = "127.0.0.1";
              # No login: the tailnet is the only access control.
              authentication.disabled = true;
            };
          };
        };

        tsnsrv.services.soulseek.toURL = "http://127.0.0.1:${toString config.services.slskd.settings.web.port}";
      };

      # The module makes shares read-only, and the share is the downloads directory.
      systemd.services.slskd.serviceConfig.ReadOnlyPaths = lib.mkForce [ ];
    };
}

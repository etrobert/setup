{
  flake.nixosModules.slskd =
    { config, lib, ... }:
    {
      sops.secrets.slskd-username.sopsFile = ../../secrets/charon.yaml;
      sops.secrets.slskd-password.sopsFile = ../../secrets/charon.yaml;
      sops.templates.slskd-env.content = ''
        SLSKD_SLSK_USERNAME=${config.sops.placeholder.slskd-username}
        SLSKD_SLSK_PASSWORD=${config.sops.placeholder.slskd-password}
      '';

      services = {
        slskd = {
          enable = true;
          environmentFile = config.sops.templates.slskd-env.path;
          openFirewall = true;

          settings = {
            # Siblings on one filesystem: completion is a rename, not a copy.
            directories = {
              downloads = "/srv/downloads/slskd/downloads";
              incomplete = "/srv/downloads/slskd/incomplete";
            };

            # Share back what we fetched, the way transmission seeds.
            shares = {
              directories = [ config.services.slskd.settings.directories.downloads ];
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

      systemd = {
        services.slskd = {
          # The module makes shares read-only, and the share is the downloads directory.
          serviceConfig.ReadOnlyPaths = lib.mkForce [ ];

          # Without the mount, downloads would fill the root filesystem.
          unitConfig.RequiresMountsFor = [ "/srv/downloads" ];
        };

        # ReadWritePaths= needs them to exist; the module only creates its StateDirectory.
        tmpfiles.settings.slskd =
          lib.genAttrs
            [
              "/srv/downloads/slskd"
              config.services.slskd.settings.directories.downloads
              config.services.slskd.settings.directories.incomplete
            ]
            (_: {
              d = {
                inherit (config.services.slskd) user group;
              };
            });
      };
    };
}

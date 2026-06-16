{ self, ... }:
{
  flake = {
    nixosModules.server =
      {
        etiennerobert-com,
        creatures,
        rift-radar,
        config,
        pkgs,
        lib,
        ...
      }:
      let
        inherit (pkgs.stdenv.hostPlatform) system;
        creaturesPackage = creatures.packages.${system}.default;
      in
      {
        imports = [
          self.nixosModules.umami
          rift-radar.nixosModules.default
        ];

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        services = {
          ddclient = {
            enable = true;
            protocol = "namecheap";
            server = "dynamicdns.park-your-domain.com";
            username = "etiennerobert.com";
            passwordFile = config.age.secrets.ddclient-password-etiennerobert-com.path;
            domains = [
              "test"
              "creatures"
              "files"
              "adele"
              "umami"
              "images"
              "rift"
            ];
            interval = "5min";
            usev6 = "no";
            usev4 = "webv4";
          };

          filebrowser = {
            enable = true;
            settings = {
              root = "/srv/files/adele";
              port = 8081;
              username = "adele";
              password = "$2a$10$IJiPBcbqVvJnAilE8Gs.uulWMWfq18tOEvlcYqaz8RvWjWP3sgBUK";
            };
          };

          caddy = {
            enable = true;
            virtualHosts = {
              "test.etiennerobert.com".extraConfig = /* caddy */ ''
                root * ${etiennerobert-com.packages.${system}.default}
                encode zstd gzip
                try_files {path} /index.html
                file_server
              '';
              "creatures.etiennerobert.com".extraConfig = /* caddy */ ''
                reverse_proxy localhost:3000
              '';
              "files.etiennerobert.com".extraConfig = /* caddy */ ''
                root * /srv/files
                header Access-Control-Allow-Origin *
                file_server browse
              '';
              "adele.etiennerobert.com".extraConfig = /* caddy */ ''
                reverse_proxy localhost:8081
              '';
              "umami.etiennerobert.com".extraConfig = /* caddy */ ''
                reverse_proxy localhost:3001
              '';
              "images.etiennerobert.com".extraConfig = /* caddy */ ''
                reverse_proxy localhost:8889
              '';
            };
          };

          # Redis cache, backend systemd unit and the rift.etiennerobert.com
          # Caddy vhost are provided by rift-radar's own nixosModule (imported
          # above); we only supply host-specific config.
          rift-radar = {
            enable = true;
            hostName = "rift.etiennerobert.com";
            riotKeyFile = config.age.secrets.riot-api-key.path;
          };
        };

        age.secrets.ddclient-password-etiennerobert-com.file = ../secrets/ddclient-password-etiennerobert-com.age;
        age.secrets.riot-api-key.file = ../secrets/riot-api-key.age;

        # Filebrowser creates files/dirs via the web UI with modes 0640/0750 (settings.FileMode /
        # settings.DirMode defaults), which grant no world access. Add caddy to the filebrowser
        # group so it can serve uploaded content.
        users.users.caddy.extraGroups = [ "filebrowser" ];

        systemd = {
          # Override the filebrowser module's default UMask of 0077, which would strip the group
          # bits from filebrowser's 0640/0750 creation modes (giving 0600/0700) and block caddy.
          # Override the filebrowser module's tmpfiles rule which resets /srv/files/adele to 0700 on every boot,
          # which would block caddy from traversing into the directory.
          tmpfiles.settings.filebrowser."/srv/files/adele".d.mode = lib.mkForce "0755";

          services = {
            filebrowser.serviceConfig.UMask = lib.mkForce "0022";

            creatures = {
              description = "Creatures server";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              serviceConfig = {
                ExecStart = "${creaturesPackage}/bin/creatures-server";
                Restart = "on-failure";
                DynamicUser = true;
              };
            };

            imgproxy = {
              description = "imgproxy";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];
              serviceConfig = {
                ExecStart = "${pkgs.imgproxy}/bin/imgproxy";
                Restart = "on-failure";
                DynamicUser = true;
                Environment = [
                  "IMGPROXY_JPEG_PROGRESSIVE=true"
                  "IMGPROXY_BIND=localhost:8889"
                  "IMGPROXY_LOCAL_FILESYSTEM_ROOT=/srv/files"
                  "IMGPROXY_USE_ETAG=true"
                  "IMGPROXY_ALLOWED_SOURCES=local://"
                ];
              };
            };
          };
        };
      };
  };
}

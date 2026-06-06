{ self, ... }:
{
  flake = {
    nixosModules.server =
      {
        etiennerobert-com,
        creatures,
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
        imports = [ self.nixosModules.umami ];

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
            package = pkgs.caddy.withPlugins {
              plugins = [
                "github.com/caddyserver/cache-handler@v0.16.0"
                "github.com/darkweak/storages/badger/caddy@v0.0.19"
              ];
              hash = "sha256-ueSf6zEs/tbbboSWsaxdovL204GwMY0gUihrcm5hRXE=";
            };
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
                cache {
                  badger {
                    path /var/cache/caddy-imgproxy
                  }
                  ttl 720h
                }
                reverse_proxy localhost:8889
              '';
            };
          };
        };

        age.secrets.ddclient-password-etiennerobert-com.file = ../secrets/ddclient-password-etiennerobert-com.age;

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
          tmpfiles.rules = [ "d /var/cache/caddy-imgproxy 0700 caddy caddy -" ];

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
                  "IMGPROXY_BIND=localhost:8889"
                  "IMGPROXY_LOCAL_FILESYSTEM_ROOT=/srv/files"
                  "IMGPROXY_USE_ETAG=true"
                ];
              };
            };
          };
        };
      };
  };
}

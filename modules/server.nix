{ self, inputs, ... }:
{
  flake = {
    nixosModules.server =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        inherit (pkgs.stdenv.hostPlatform) system;
      in
      {
        imports = [
          self.nixosModules.umami
          inputs.rift-radar.nixosModules.default
          inputs.rack.nixosModules.default
          inputs.creatures.nixosModules.default
          inputs.countdown.nixosModules.default
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
              "countdown"
              "files"
              "adele"
              "umami"
              "images"
              "rift"
              "rack"
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
                root * ${inputs.etiennerobert-com.packages.${system}.default}
                encode zstd gzip
                try_files {path} /index.html
                file_server
              '';
              "files.etiennerobert.com".extraConfig = /* caddy */ ''
                root * /srv/files
                header Access-Control-Allow-Origin *
                # Metadata here (info.toml, dir listings) is hand-edited live and
                # must take effect without a rebuild. Force revalidation so the
                # browser's heuristic cache can't serve stale data; ETag keeps it
                # cheap (304s when unchanged).
                header Cache-Control "no-cache"
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
            riotKey = config.age.secrets.riot-api-key;
          };

          # The rack.etiennerobert.com Caddy vhost is provided by rack's own
          # nixosModule (imported above); we only point it at the domain. Piece
          # photos/metadata are served separately from files.etiennerobert.com.
          rack = {
            enable = true;
            hostName = "rack.etiennerobert.com";
          };

          creatures = {
            enable = true;
            hostName = "creatures.etiennerobert.com";
          };

          countdown = {
            enable = true;
            hostName = "countdown.etiennerobert.com";
          };
        };

        age.secrets.ddclient-password-etiennerobert-com.file = ../secrets/ddclient-password-etiennerobert-com.age;
        age.secrets.riot-api-key.file = ../secrets/riot-api-key.age;

        # Filebrowser creates files/dirs via the web UI with modes 0640/0750 (settings.FileMode /
        # settings.DirMode defaults), which grant no world access. Add caddy to the filebrowser
        # group so it can serve uploaded content.
        users.users.caddy.extraGroups = [ "filebrowser" ];

        systemd = {
          # Own /srv/files as soft:users with the setgid bit so it can be populated over
          # plain SSH/scp without sudo, and so new entries consistently inherit group
          # "users" (caddy/imgproxy read via the world r-x bits, so they need no membership).
          # Without this the dir is root:root 0755 — every write needs sudo, and ad-hoc
          # `sudo cp` leaves a mix of root/soft-owned files. The filebrowser-managed
          # adele/ subtree keeps its own ownership (see the caddy group + UMask overrides).
          tmpfiles.settings.filebrowser = {
            "/srv/files".d = {
              user = "soft";
              group = "users";
              mode = "2775";
            };

            # Override the filebrowser module's tmpfiles rule which resets /srv/files/adele to 0700
            # on every boot, which would block caddy from traversing into the directory.
            "/srv/files/adele".d.mode = lib.mkForce "0755";
          };

          # Auto-expiring drop-zone for files shared over files.etiennerobert.com:
          # tmpfiles-clean removes anything left untouched (atime) for 30 days.
          # 2775/users mirror /srv/files so drops stay readable by caddy/imgproxy.
          tmpfiles.settings.share-temp."/srv/files/temp".d = {
            user = "soft";
            group = "users";
            mode = "2775";
            age = "30d";
          };

          services = {
            # Override the filebrowser module's default UMask of 0077, which would strip the group
            # bits from filebrowser's 0640/0750 creation modes (giving 0600/0700) and block caddy.
            filebrowser.serviceConfig.UMask = lib.mkForce "0022";

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

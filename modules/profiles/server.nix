{ self, inputs, ... }:
{
  flake = {
    nixosModules.server =
      {
        config,
        pkgs,
        ...
      }:
      let
        inherit (pkgs.stdenv.hostPlatform) system;
      in
      {
        imports = [
          self.nixosModules.ddclient
          self.nixosModules.filebrowser
          self.nixosModules.imgproxy
          self.nixosModules.umami
          inputs.rift-radar.nixosModules.default
          inputs.rack.nixosModules.default
          inputs.creatures.nixosModules.default
          inputs.countdown.nixosModules.default
          inputs.nutricalc.nixosModules.default
        ];

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        services = {
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
            };
          };

          # Redis cache, backend systemd unit and the rift.etiennerobert.com
          # Caddy vhost are provided by rift-radar's own nixosModule (imported
          # above); we only supply host-specific config.
          rift-radar = {
            enable = true;
            hostName = "rift.etiennerobert.com";
            riotKey = config.age.secrets.riot-api-key;

            # 8080 is too contended to hold: the lafraise dev backend binds it,
            # and open-webui already had to move off it.
            port = 8082;
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

          # A friend's project, hosted here at his request. Unlike the other
          # sites this input is not ours, so his pushes to main reach tower
          # through the hourly flake-update PR without review.
          nutricalc = {
            enable = true;
            hostName = "nutricalc.etiennerobert.com";
          };
        };

        age.secrets.riot-api-key.file = ../../secrets/riot-api-key.age;

        systemd = {
          # Own /srv/files as soft:users with the setgid bit so it can be populated over
          # plain SSH/scp without sudo, and so new entries consistently inherit group
          # "users" (caddy/imgproxy read via the world r-x bits, so they need no membership).
          # Without this the dir is root:root 0755 — every write needs sudo, and ad-hoc
          # `sudo cp` leaves a mix of root/soft-owned files. The filebrowser-managed
          # adele/ subtree keeps its own ownership (see modules/features/filebrowser.nix).
          tmpfiles.settings.filebrowser."/srv/files".d = {
            user = "soft";
            group = "users";
            mode = "2775";
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
        };
      };
  };
}

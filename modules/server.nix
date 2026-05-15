_: {
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
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        # Overwrite to be able to access that from LAN
        # hairpin NAT trap
        # Better fix would be to have DNS server on LAN
        networking.hosts."192.168.0.130" = [
          "test.etiennerobert.com"
          "creatures.etiennerobert.com"
          "files.etiennerobert.com"
          "adele.etiennerobert.com"
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
            };
          };
        };

        age.secrets.ddclient-password-etiennerobert-com.file = ../secrets/ddclient-password-etiennerobert-com.age;

        systemd = {
          # Override the filebrowser module's hardcoded UMask of 0077 so new files/dirs are world-readable (644/755),
          # making them accessible to caddy.
          services.filebrowser.serviceConfig.UMask = lib.mkForce "0022";
          # Override the filebrowser module's tmpfiles rule which resets /srv/files/adele to 0700 on every boot,
          # which would block caddy from traversing into the directory.
          tmpfiles.settings.filebrowser."/srv/files/adele".d.mode = lib.mkForce "0755";

          services.creatures = {
            description = "Creatures server";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig = {
              ExecStart = "${creaturesPackage}/bin/creatures-server";
              Restart = "on-failure";
              DynamicUser = true;
            };
          };
        };
      };
  };
}

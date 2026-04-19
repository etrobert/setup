_: {
  flake = {
    nixosModules.server =
      {
        etiennerobert-com,
        config,
        pkgs,
        ...
      }:
      let
        inherit (pkgs.stdenv.hostPlatform) system;
      in
      {
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        # Overwrite to be able to access that from LAN
        # hairpin NAT trap
        # Better fix would be to have DNS server on LAN
        networking.hosts."192.168.0.130" = [ "test.etiennerobert.com" ];

        services.ddclient = {
          enable = true;
          protocol = "namecheap";
          server = "dynamicdns.park-your-domain.com";
          username = "etiennerobert.com";
          passwordFile = config.age.secrets.ddclient-password-etiennerobert-com.path;
          domains = [ "test" ];
          interval = "5min";
          usev6 = "no";
          usev4 = "webv4";
        };

        age.secrets.ddclient-password-etiennerobert-com.file = ../../../secrets/ddclient-password-etiennerobert-com.age;

        services.caddy = {
          enable = true;
          virtualHosts."test.etiennerobert.com".extraConfig = /* caddy */ ''
            root * ${etiennerobert-com.packages.${system}.default}
            encode zstd gzip
            try_files {path} /index.html
            file_server
          '';
        };

      };
  };
}

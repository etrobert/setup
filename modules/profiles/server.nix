{ self, inputs, ... }:
{
  flake = {
    nixosModules.server = _: {
      imports = [
        self.nixosModules.caddy
        self.nixosModules.ddclient
        self.nixosModules.filebrowser
        self.nixosModules.imgproxy
        self.nixosModules.jitsiMeet
        self.nixosModules.umami
        inputs.rack.nixosModules.default
      ];

      services = {
        caddy.virtualHosts = {
          "files.etiennerobert.com".extraConfig = /* caddy */ ''
            root * /tank/public
            header Access-Control-Allow-Origin *
            # Metadata here (info.toml, dir listings) is hand-edited live and
            # must take effect without a rebuild. Force revalidation so the
            # browser's heuristic cache can't serve stale data; ETag keeps it
            # cheap (304s when unchanged).
            header Cache-Control "no-cache"
            file_server browse
          '';
        };

        # The rack.etiennerobert.com Caddy vhost is provided by rack's own
        # nixosModule (imported above); we only point it at the domain. Piece
        # photos/metadata are served separately from files.etiennerobert.com.
        rack = {
          enable = true;
          hostName = "rack.etiennerobert.com";
        };
      };

      systemd.tmpfiles.settings.public = {
        # setgid so scp'd files inherit "users"; caddy/imgproxy read via o+rx.
        # z/e, never d: a boot without the pool must not create this on the root fs.
        "/tank/public".z = {
          user = "soft";
          group = "users";
          mode = "2775";
        };

        # Drop-zone: expires 30 days after the last write (atime is off on tank).
        "/tank/public/temp".e = {
          user = "soft";
          group = "users";
          mode = "2775";
          age = "30d";
        };
      };
    };
  };
}

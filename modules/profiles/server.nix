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

        # The rack.etiennerobert.com Caddy vhost is provided by rack's own
        # nixosModule (imported above); we only point it at the domain. Piece
        # photos/metadata are served separately from files.etiennerobert.com.
        rack = {
          enable = true;
          hostName = "rack.etiennerobert.com";
        };
      };

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

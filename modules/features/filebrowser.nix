_: {
  flake.nixosModules.filebrowser =
    { lib, ... }:
    {
      services = {
        filebrowser = {
          enable = true;
          settings = {
            root = "/tank/public/adele";
            port = 8081;
            username = "adele";
            password = "$2a$10$IJiPBcbqVvJnAilE8Gs.uulWMWfq18tOEvlcYqaz8RvWjWP3sgBUK";
          };
        };

        caddy.virtualHosts."adele.etiennerobert.com".extraConfig = /* caddy */ ''
          reverse_proxy localhost:8081
        '';
      };

      # Filebrowser creates files/dirs via the web UI with modes 0640/0750 (settings.FileMode /
      # settings.DirMode defaults), which grant no world access. Add caddy to the filebrowser
      # group so it can serve uploaded content.
      users.users.caddy.extraGroups = [ "filebrowser" ];

      systemd = {
        # The module's d would reset the root to 0700 (blocking caddy); any rule
        # here trips tmpfiles' unsafe-path-transition guard under soft's parent.
        tmpfiles.settings.filebrowser."/tank/public/adele" = lib.mkForce { };

        # Override the filebrowser module's default UMask of 0077, which would strip the group
        # bits from filebrowser's 0640/0750 creation modes (giving 0600/0700) and block caddy.
        services.filebrowser.serviceConfig.UMask = lib.mkForce "0022";
      };
    };
}

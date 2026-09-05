# Adele's upload portal at adele.etiennerobert.com.
#
# It only provides the browser she uploads through: the files themselves are
# served publicly by caddy from files.etiennerobert.com/adele/ (server.nix).
#
# filebrowser-quantum rather than nixpkgs' `services.filebrowser`, whose
# upstream archived on 2026-09-01 with no further security fixes. Quantum is
# the maintained fork and has no NixOS module, hence the hand-rolled unit.
_: {
  flake.nixosModules.filebrowser =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      port = 8081;
      root = "/srv/files/adele";

      configFile = (pkgs.formats.yaml { }).generate "filebrowser.yaml" {
        server = {
          inherit port;

          listen = "127.0.0.1";
          # Not the v2 database.db beside it: a different schema, kept for rollback.
          database = "/var/lib/filebrowser/quantum.db";
          cacheDir = "/var/cache/filebrowser";
          sources = [ { path = root; } ];
        };

        auth.methods.password = {
          enabled = true;
          signup = false;
        };

        # Everything but download defaults to false, which would leave her a
        # portal she can only read from.
        userDefaults.account.permissions = {
          create = true;
          modify = true;
          delete = true;
        };
      };
    in
    {
      age.secrets.adele-filebrowser-password = {
        file = ../../secrets/adele-filebrowser-password.age;
        owner = "filebrowser";
      };

      users = {
        users.filebrowser = {
          isSystemUser = true;
          group = "filebrowser";
        };

        groups.filebrowser = { };
      };

      # 0755 so caddy can traverse it to serve files.etiennerobert.com/adele/.
      systemd.tmpfiles.settings.filebrowser.${root}.d = {
        mode = "0755";
        user = "filebrowser";
        group = "filebrowser";
      };

      systemd.services.filebrowser = {
        description = "File Browser Quantum";

        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          # Idempotent: creates adele on first run, resets her password after.
          ExecStartPre = pkgs.writeShellScript "filebrowser-account" ''
            exec ${lib.getExe pkgs.filebrowser-quantum} set -u \
              "adele,$(cat ${config.age.secrets.adele-filebrowser-password.path})" \
              -c ${configFile}
          '';

          ExecStart = "${lib.getExe pkgs.filebrowser-quantum} -c ${configFile}";

          User = "filebrowser";
          Group = "filebrowser";
          StateDirectory = "filebrowser";
          CacheDirectory = "filebrowser";
          WorkingDirectory = root;
          # Uploads must land world-readable for caddy to serve them.
          UMask = "0022";
        };
      };

      services.caddy.virtualHosts."adele.etiennerobert.com".extraConfig = # caddy
        ''
          reverse_proxy localhost:${toString port}
        '';
    };
}

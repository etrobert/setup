_: {
  flake.nixosModules.pimsync =
    { pkgs, lib, ... }:
    let
      configFile = pkgs.writeText "pimsync.conf" ''
        status_path "~/.local/share/pimsync/status/"

        storage contacts_icloud {
          type carddav
          url https://contacts.icloud.com
          username etiennerobert33@gmail.com
          interval 30
          password {
            cmd cat /run/agenix/apple-pimsync-password
          }
        }

        storage contacts_local {
          type vdir/vcard
          path ~/.local/share/contacts/
          fileext vcf
          interval 30
        }

        pair contacts {
          storage_a contacts_local
          storage_b contacts_icloud
          collections all
        }
      '';
    in
    {
      age.secrets.apple-pimsync-password = {
        owner = "soft";
        file = ../secrets/apple-pimsync-password.age;
      };

      systemd.user.services.pimsync = {
        description = "pimsync calendar and contacts synchronization";
        partOf = [ "network-online.target" ];
        after = [ "run-agenix.d.mount" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.pimsync} -v warn -c ${configFile} daemon";
        };
      };
    };
}

{ self, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.pimsync-wrapped =
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
        self.lib.wrapPackage pkgs {
          package = pkgs.pimsync;
          flags = [ "-c ${configFile}" ];
          # The config's `password { cmd cat … }` is spawned via execvp, so cat has to
          # be on the wrapper's PATH.
          runtimeInputs = [ pkgs.coreutils ];
        };
    };

  flake.nixosModules.pimsync =
    {
      self,
      pkgs,
      lib,
      ...
    }:
    let
      pimsync = self.packages.${pkgs.stdenv.hostPlatform.system}.pimsync-wrapped;
    in
    {
      age.secrets.apple-pimsync-password = {
        owner = "soft";
        file = ../../secrets/apple-pimsync-password.age;
      };

      environment.systemPackages = [ pimsync ];

      systemd.user.services.pimsync = {
        description = "pimsync calendar and contacts synchronization";
        partOf = [ "network-online.target" ];
        after = [ "run-agenix.d.mount" ];
        wantedBy = [ "default.target" ];
        unitConfig.ConditionUser = "!@system";
        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe pimsync} -v info daemon";
        };
      };
    };
}

_: {
  perSystem =
    { pkgs, ... }:
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
        pkgs.wrapPackage {
          package = pkgs.pimsync;
          flags = [ "-c ${configFile}" ];
          # The config's `password { cmd cat … }` is spawned via execvp, so cat has to
          # be on the wrapper's PATH.
          runtimeInputs = [ pkgs.coreutils ];
        };
    };
}

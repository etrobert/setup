# Browse /tank from aaron (Finder), leod, and the iPhone (Files app):
# SMB as user soft, reachable over Tailscale only.
_: {
  flake.nixosModules.samba =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      age.secrets.smb-credentials.file = ../../secrets/smb-credentials.age;

      services.samba = {
        enable = true;

        # SMB over TCP 445 only — no NetBIOS name service or NT-domain
        # machinery.
        nmbd.enable = false;
        winbindd.enable = false;

        settings = {
          global = {
            "disable netbios" = "yes";
            interfaces = "lo tailscale0";
            "bind interfaces only" = "yes";

            # Apple SMB extensions for macOS/iOS clients, with Finder
            # metadata stored in xattr streams.
            "vfs objects" = "fruit streams_xattr";
            "fruit:metadata" = "stream";
          };

          tank = {
            path = "/tank";
            "read only" = "no";
          };
        };
      };

      systemd.services.samba-passdb =
        let
          # Samba's password database is imperative state; deriving it from the
          # agenix secret keeps the only manual step at authoring the secret.
          # The secret is a mount.cifs credentials file (username=/password=
          # lines), shared with client machines that mount the share.
          smb-passdb = pkgs.writeShellApplication {
            name = "smb-passdb";

            runtimeInputs = [
              config.services.samba.package
              pkgs.gnused
            ];

            inheritPath = false;

            text = /* bash */ ''
              password="$(sed --quiet 's/^password=//p' ${config.age.secrets.smb-credentials.path})"
              printf '%s\n%s\n' "$password" "$password" | smbpasswd -s -a soft
            '';
          };
        in
        {
          description = "Provision the soft Samba user from the smb-password secret";
          before = [ "samba-smbd.service" ];
          requiredBy = [ "samba-smbd.service" ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe smb-passdb;
          };
        };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 445 ];
    };
}

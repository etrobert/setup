# Copies charon's finished torrents into tank. charon removes them itself
# once seeded enough (see transmission.nix), so this only ever copies.
let
  landing = "/tank/media/torrents";
in
{
  flake.nixosModules.torrentPull =
    { pkgs, ... }:
    {
      systemd = {
        services.torrent-pull = {
          description = "Pull finished torrents from charon";

          path = with pkgs; [
            openssh
            rsync
          ];

          # ProtectSystem=strict leaves nowhere for a control socket.
          script = /* bash */ ''
            rsync --archive --partial --rsh 'ssh -o ControlMaster=no' \
              charon:/var/lib/transmission/Downloads/ ${landing}/
          '';

          serviceConfig = {
            Type = "oneshot";
            # soft: the key charon accepts, and the owner of the landing zone.
            User = "soft";
            Environment = "HOME=/home/soft";
            ProtectSystem = "strict";
            ReadWritePaths = [ landing ];
          };
        };

        timers.torrent-pull = {
          description = "Schedule the torrent pull";
          wantedBy = [ "timers.target" ];
          timerConfig.OnCalendar = "*:0/15";
        };

        # World-readable so jellyfin can serve it; rsync creates the rest 755.
        tmpfiles.settings.torrent-pull.${landing}.z = {
          user = "soft";
          group = "users";
          mode = "0755";
        };
      };
    };
}

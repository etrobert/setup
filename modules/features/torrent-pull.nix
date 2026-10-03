# Copies charon's finished torrents into tank. charon removes them itself
# once seeded enough (see transmission.nix), so this only ever copies.
let
  landing = "/tank/media/torrents";
in
{
  flake.nixosModules.torrent-pull =
    { pkgs, ... }:
    {
      systemd = {
        services.torrent-pull = {
          description = "Pull finished torrents from charon";

          path = with pkgs; [
            openssh
            rsync
          ];

          # --chmod: jellyfin must read the result
          # --delay-updates: jellyfin scans the landing zone; a half-copied file stays under .~tmp~
          # ControlMaster: no writable home here
          script = /* bash */ ''
            rsync --archive --partial --delay-updates --exclude='*.part' --chmod=Do+rx \
              --rsh 'ssh -o ControlMaster=no' \
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
      };
    };
}

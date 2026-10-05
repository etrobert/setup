# Mirrors charon's finished torrents into tank. charon removes them once
# seeded enough (see transmission.nix); the *arrs' hardlinks keep imported files.
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

          # Persistent=true fires the missed run at boot, before DNS resolves.
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          path = with pkgs; [
            openssh
            rsync
          ];

          # --chmod: jellyfin must read the result
          # --delay-updates: the *arrs import from the landing zone; a half-copied file stays under .~tmp~
          # ControlMaster: no writable home here
          script = /* bash */ ''
            rsync --archive --partial --delay-updates --delete --exclude='*.part' --chmod=Do+rx \
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

          timerConfig = {
            # Lidarr polls its queue every minute; an idle pull costs 0.25 s.
            OnCalendar = "minutely";
            Persistent = true;
          };
        };
      };
    };
}

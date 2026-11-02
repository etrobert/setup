# Mirrors the download host's finished torrents into /tank/media/torrents.
{
  flake.nixosModules.download-pull =
    { pkgs, ... }:
    {
      systemd.services.torrent-pull = {
        description = "Pull torrent downloads";

        # Every start counts: the minutely timer puts 2 in the window, a boot or switch 1 more.
        startLimitBurst = 4;
        # Longer than 4 attempts at ConnectTimeout, so a dead link always exhausts the retries.
        startLimitIntervalSec = 90;

        path = with pkgs; [
          openssh
          rsync
        ];

        # --chmod: jellyfin must read the result
        # --delay-updates: the landing zone is scanned; a half-copied file stays under .~tmp~
        # --delete: imports hardlink into the library, so the landing zone ends when seeding does
        # protect: the category folders exist for the health checks before transmission creates them
        # ControlMaster: no writable home here
        # ConnectTimeout: a failed attempt must end quickly to count towards the start limit
        script = /* bash */ ''
          rsync --archive --partial --delay-updates --chmod=Do+rx --delete --filter='protect /*/' \
            --rsh 'ssh -o ControlMaster=no -o ConnectTimeout=10' \
            soft@51.91.29.38:/storage/downloads/ /tank/media/torrents/
        '';

        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          RestartSec = "5s";
          # direct: the ntfy OnFailure= alert fires only once the retries run out.
          RestartMode = "direct";
          # soft: the key the download host accepts, and the owner of the landing zone.
          User = "soft";
          Environment = "HOME=/home/soft";
          ProtectSystem = "strict";
          # The parent, so rsync creates a missing landing zone instead of the unit failing.
          ReadWritePaths = [ "/tank/media" ];
        };
      };

      systemd.timers.torrent-pull = {
        description = "Schedule the torrent pull";
        wantedBy = [ "timers.target" ];

        timerConfig = {
          # Radarr polls its queue every minute; an idle pull costs 0.25 s.
          OnCalendar = "minutely";
          Persistent = true;
        };
      };
    };
}

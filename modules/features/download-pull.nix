# Copies the download host's finished downloads into /tank/media. That host
# removes them itself once shared long enough (transmission.nix, slskd.nix).
{
  flake.nixosModules.download-pull =
    { lib, pkgs, ... }:
    let
      pull =
        {
          name,
          from,
          to,
          extraFlags,
        }:
        {
          services."${name}-pull" = {
            description = "Pull ${name} downloads";

            # Persistent=true fires the missed run at boot; charon resolves only once tailscale runs.
            after = [ "tailscaled-autoconnect.service" ];

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
            # ControlMaster: no writable home here
            # ConnectTimeout: a failed attempt must end quickly to count towards the start limit
            script = /* bash */ ''
              rsync --archive --partial --delay-updates --chmod=Do+rx ${extraFlags} \
                --rsh 'ssh -o ControlMaster=no -o ConnectTimeout=10' \
                charon:${from}/ ${to}/
            '';

            serviceConfig = {
              Type = "oneshot";
              # Tailscale runs before it has fetched its peers, so charon fails to resolve for a few seconds.
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

          timers."${name}-pull" = {
            description = "Schedule the ${name} pull";
            wantedBy = [ "timers.target" ];

            timerConfig = {
              # Lidarr polls its queue every minute; an idle pull costs 0.25 s.
              OnCalendar = "minutely";
              Persistent = true;
            };
          };
        };
    in
    {
      systemd = lib.mkMerge [
        # No --delete: jellyfin plays some torrents straight from the landing zone.
        (pull {
          name = "torrent";
          from = "/var/lib/transmission/Downloads";
          to = "/tank/media/torrents";
          extraFlags = "--exclude='*.part'";
        })
        # A mirror: imports copy albums out, so the landing zone ends when the share does.
        (pull {
          name = "soulseek";
          from = "/var/lib/slskd/downloads";
          to = "/tank/media/soulseek";
          extraFlags = "--delete";
        })
      ];
    };
}

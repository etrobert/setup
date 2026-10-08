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

            path = with pkgs; [
              openssh
              rsync
            ];

            # --chmod: jellyfin must read the result
            # --delay-updates: the landing zone is scanned; a half-copied file stays under .~tmp~
            # ControlMaster: no writable home here
            script = /* bash */ ''
              rsync --archive --partial --delay-updates --chmod=Do+rx ${extraFlags} \
                --rsh 'ssh -o ControlMaster=no' \
                charon:${from}/ ${to}/
            '';

            serviceConfig = {
              Type = "oneshot";
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

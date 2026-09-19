# Copies charon's finished torrents into tank, then removes from charon the
# ones that have met c411's seeding rule (72 h or ratio 1.0 per torrent,
# https://c411.org/wiki/ratio-seedtime). Runs as soft: the key charon accepts
# and the owner of the landing zone.
let
  landing = "/tank/media/torrents";
  seedSeconds = 72 * 3600;
in
{
  flake.nixosModules.torrentPull =
    { pkgs, ... }:
    {
      systemd.services.torrent-pull = {
        description = "Pull finished torrents from charon";

        path = with pkgs; [
          jq
          openssh
          rsync
          transmission_4
        ];

        script = /* bash */ ''
          set -u -o pipefail

          # ProtectSystem=strict leaves nowhere for a control socket.
          rsync --archive --partial --rsh 'ssh -o ControlMaster=no' \
            charon:/var/lib/transmission/Downloads/ ${landing}/

          transmission-remote charon --json -t all -i |
            jq --raw-output --argjson min ${toString seedSeconds} '
              .result.torrents[]
              | select(.percent_done == 1 and (.seconds_seeding >= $min or .upload_ratio >= 1))
              | "\(.hash_string) \(.name)"
            ' |
            while read -r hash name; do
              echo "removing $name"
              transmission-remote charon -t "$hash" --remove-and-delete
            done
        '';

        serviceConfig = {
          Type = "oneshot";
          User = "soft";
          Environment = "HOME=/home/soft";
          ProtectSystem = "strict";
          ReadWritePaths = [ landing ];
        };
      };

      systemd.timers.torrent-pull = {
        description = "Schedule the torrent pull";
        wantedBy = [ "timers.target" ];
        timerConfig.OnCalendar = "*:0/15";
      };
    };
}

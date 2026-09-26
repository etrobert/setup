# Copies charon's finished torrents into tank. charon removes them itself
# once seeded enough (see transmission.nix), so this only ever copies.
let
  video = "/tank/media/torrents";
  # Apart from video: the video landing zone is jellyfin's library.
  music = "/tank/media/torrents-music";
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

          # --chmod: jellyfin must read the result
          # ControlMaster: no writable home here
          script = /* bash */ ''
            pull() {
              rsync --archive --partial --exclude='*.part' --chmod=Do+rx \
                --rsh 'ssh -o ControlMaster=no' "$@"
            }

            pull --exclude='/music/' charon:/var/lib/transmission/Downloads/ ${video}/
            pull charon:/var/lib/transmission/Downloads/music/ ${music}/
          '';

          serviceConfig = {
            Type = "oneshot";
            # soft: the key charon accepts, and the owner of the landing zone.
            User = "soft";
            Environment = "HOME=/home/soft";
            ProtectSystem = "strict";
            ReadWritePaths = [
              video
              music
            ];
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

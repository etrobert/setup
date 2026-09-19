# Copies charon's finished torrents into tank. charon removes them itself
# once seeded enough (see transmission.nix), so this only ever copies.
let
  landing = "/tank/media/torrents";
in
{
  flake.nixosModules.torrentPull =
    { pkgs, lib, ... }:
    let
      torrent-pull = pkgs.writeShellApplication {
        name = "torrent-pull";

        runtimeInputs = with pkgs; [
          openssh
          rsync
        ];

        inheritPath = false;

        # ProtectSystem=strict leaves nowhere for a control socket.
        text = /* bash */ ''
          rsync --archive --partial --rsh 'ssh -o ControlMaster=no' \
            charon:/var/lib/transmission/Downloads/ ${landing}/
        '';
      };
    in
    {
      systemd.services.torrent-pull = {
        description = "Pull finished torrents from charon";

        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe torrent-pull;
          # soft: the key charon accepts, and the owner of the landing zone.
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

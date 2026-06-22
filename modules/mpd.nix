_: {
  flake.nixosModules.mpd =
    { pkgs, ... }:
    let
      user = "soft";
      home = "/home/${user}";
      dataDir = "${home}/.local/share/mpd";
      musicDir = "${home}/sync/music";

      mpdConf = pkgs.writeText "mpd.conf" ''
        music_directory    "${musicDir}"
        playlist_directory "${home}/sync/playlists"
        db_file            "${dataDir}/tag_cache"
        state_file         "${dataDir}/state"
        sticker_file       "${dataDir}/sticker.sql"
        bind_to_address    "127.0.0.1"
        restore_paused     "yes"
        auto_update        "yes"

        audio_output {
          type "pipewire"
          name "PipeWire"
        }
      '';

      mpdris2Conf = pkgs.writeText "mpDris2.conf" ''
        [Connection]
        host = 127.0.0.1
        port = 6600
        music_dir = ${musicDir}

        [Bling]
        notify = True
        mmkeys = False
      '';
    in
    {
      environment.systemPackages = [ pkgs.mpc ]; # Minimalist command line interface to MPD

      systemd.user = {
        services = {
          # Run as a user service so systemd provides XDG_RUNTIME_DIR and the
          # PipeWire socket is reachable without hardcoding the user's UID.
          mpd = {
            description = "Music Player Daemon";
            after = [
              "network.target"
              "sound.target"
            ];
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "notify";
              ExecStart = "${pkgs.mpd}/bin/mpd --no-daemon ${mpdConf}";
            };
          };

          mpdris2 = {
            description = "MPRIS 2 support for MPD";
            after = [ "mpd.service" ];
            partOf = [ "graphical-session.target" ];
            bindsTo = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              Type = "simple";
              Restart = "on-failure";
              RestartSec = "5s";
              ExecStart = "${pkgs.mpdris2}/bin/mpDris2 --config ${mpdris2Conf}";
            };
          };
        };

        tmpfiles.rules = [ "d %h/.local/share/mpd 0700 - - -" ];
      };
    };
}

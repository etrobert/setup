_: {
  flake.nixosModules.mpd =
    { pkgs, ... }:
    let
      user = "soft";
      uid = 1000;
      home = "/home/${user}";
      musicDir = "${home}/sync/music";

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
      # NixOS ships a system-level services.mpd, but it runs the daemon as the
      # dedicated `mpd` system user, which cannot reach the login user's PipeWire
      # socket (/run/user/<uid>/pipewire-0). Run it as the login user instead.
      #
      # dataDir is left at its default (/var/lib/mpd): the module creates it via
      # systemd StateDirectory (chowned to the service user) and points db_file,
      # state_file and sticker_file underneath it, so nothing extra is needed.
      services.mpd = {
        enable = true;
        user = user;

        settings = {
          music_directory = musicDir;
          playlist_directory = "${home}/sync/playlists";
          bind_to_address = "127.0.0.1";
          restore_paused = "yes";
          auto_update = "yes";

          audio_output = [
            {
              type = "pipewire";
              name = "PipeWire";
            }
          ];
        };

        # bind_to_address is loopback, so nothing needs opening; set explicitly
        # to silence the module's firewall warning.
        openFirewall = false;
      };

      # The system service has no login session, so XDG_RUNTIME_DIR is unset and
      # PipeWire's per-user socket is unreachable. Point it at the user's runtime
      # dir -- this hardcoded UID is exactly what the systemd.user.service approach
      # avoids, since the user manager provides XDG_RUNTIME_DIR automatically.
      systemd.services.mpd.environment.XDG_RUNTIME_DIR = "/run/user/${toString uid}";

      # NixOS has no system module for the MPRIS bridge (it is a per-session,
      # session-bus service), so mpdris2 still has to be a user service.
      systemd.user.services.mpdris2 = {
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

      environment.systemPackages = [ pkgs.mpc ]; # Minimalist command line interface to MPD
    };
}

_: {
  flake.nixosModules.awww =
    {
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.awww ];

      systemd.user.services = {
        awww-daemon = {
          description = "Animated wallpaper daemon for Wayland";
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = lib.getExe' pkgs.awww "awww-daemon";
            Restart = "on-failure";
          };
        };

        awww-set-default-wallpaper = {
          description = "Set the default desktop wallpaper via awww";
          after = [ "awww-daemon.service" ];
          requires = [ "awww-daemon.service" ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.awww} img --transition-type none ${../assets/saint-levant.jpg}";
          };
        };
      };
    };
}

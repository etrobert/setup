_: {
  flake.nixosModules.awww =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
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

        awww-restore-on-hotplug = {
          description = "Reapply awww wallpaper when a monitor is hot-plugged";
          after = [ "awww-daemon.service" ];
          requires = [ "awww-daemon.service" ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = lib.getExe self.packages.${system}.awww-restore-on-hotplug;
            Restart = "on-failure";
          };
        };
      };
    };
}

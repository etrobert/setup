_: {
  flake.nixosModules.awww =
    {
      lib,
      pkgs,
      ...
    }:
    let
      awww-restore-on-hotplug = pkgs.writeShellApplication {
        name = "awww-restore-on-hotplug";

        runtimeInputs = [
          pkgs.niri
          pkgs.awww
        ];

        text = ''
          niri msg --json event-stream | while read -r line; do
            case "$line" in *'"ConfigLoaded"'*) ;; *) continue ;; esac
            sleep 0.5
            awww restore
          done
        '';
      };
    in
    {
      environment.systemPackages = [ pkgs.awww ];

      systemd.user.services = {
        awww-daemon = {
          description = "Animated wallpaper daemon for Wayland";

          # The daemon restores a (re)connected output by exec'ing the awww
          # client from its per-output cache, so the client must be on PATH.
          path = [ pkgs.awww ];

          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = lib.getExe' pkgs.awww "awww-daemon";
            Restart = "on-failure";
          };
        };

        awww-set-default-wallpaper = {
          description = "Set the default desktop wallpaper via awww";

          after = [
            "awww-daemon.service"
            "graphical-session.target"
          ];

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

          after = [
            "awww-daemon.service"
            "graphical-session.target"
          ];

          requires = [ "awww-daemon.service" ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = lib.getExe awww-restore-on-hotplug;
            Restart = "on-failure";
          };
        };
      };
    };
}

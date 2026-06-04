_: {
  flake.nixosModules.awww =
    {
      lib,
      pkgs,
      ...
    }:
    let
      defaultWallpaper = ../assets/saint-levant.jpg;
      setDefaultWallpaper = "${lib.getExe pkgs.awww} img --transition-type none ${defaultWallpaper}";

      # niri (26.04) has no output-connected event, so infer monitor hotplug
      # from WorkspacesChanged (workspaces are per-output) and re-apply the
      # default wallpaper only when the connected-output set actually changes.
      reapplyOnHotplug = pkgs.writeShellApplication {
        name = "awww-reapply-on-hotplug";
        runtimeInputs = [
          pkgs.awww
          pkgs.niri
          pkgs.jq
          pkgs.coreutils
        ];
        text = ''
          outputs() { niri msg --json outputs | jq -rS 'keys | join(",")'; }

          last=$(outputs)
          niri msg --json event-stream | while IFS= read -r event; do
            case "$event" in
            *'"WorkspacesChanged"'*) ;;
            *) continue ;;
            esac

            current=$(outputs)
            [ "$current" = "$last" ] && continue
            last="$current"

            # Give awww a moment to register the new output surface.
            sleep 1
            ${setDefaultWallpaper}
          done
        '';
      };
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
            ExecStart = setDefaultWallpaper;
          };
        };

        awww-reapply-on-hotplug = {
          description = "Re-apply the default wallpaper when a monitor is connected";
          after = [ "awww-daemon.service" ];
          requires = [ "awww-daemon.service" ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = lib.getExe reapplyOnHotplug;
            Restart = "on-failure";
          };
        };
      };
    };
}

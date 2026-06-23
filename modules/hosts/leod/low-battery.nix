{ pkgs, lib, ... }:

let
  notifier = pkgs.writeShellApplication {
    name = "low-battery-notify";

    inheritPath = false;

    runtimeInputs = [ pkgs.libnotify pkgs.coreutils ];

    text = /* bash */ ''
      threshold=15

      # First battery present
      bat=$(echo /sys/class/power_supply/BAT* | cut -d' ' -f1)
      [ -d "$bat" ] || exit 0

      status=$(cat "$bat/status")
      cap=$(cat "$bat/capacity")
      stamp="''${XDG_RUNTIME_DIR:-/tmp}/low-battery-notified"

      if [ "$status" = "Discharging" ] && [ "$cap" -le "$threshold" ]; then
        if [ ! -e "$stamp" ]; then
          notify-send --urgency=critical --icon=battery-caution \
            "Battery low" "Battery at ''${cap}% — plug in the charger."
          touch "$stamp"
        fi
      else
        # Reset once charging / above threshold so it can fire again next time
        rm -f "$stamp"
      fi
    '';
  };
in
{
  systemd.user.services.low-battery-notify = {
    description = "Notify when battery is low";

    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = lib.getExe notifier;
  };

  systemd.user.timers.low-battery-notify = {
    description = "Periodically check battery level";

    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "2min";
    };
  };
}

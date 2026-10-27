{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = self.lib.onlySupported {
        charge-limit = pkgs.writeShellApplication {
          name = "charge-limit";
          meta.platforms = lib.platforms.linux;
          runtimeInputs = [ pkgs.systemd ];
          inheritPath = false;
          # upower keeps the setting across reboots; thresholds are its 75/80 defaults.
          text = ''
            device=/org/freedesktop/UPower/devices/battery_BAT0
            interface=org.freedesktop.UPower.Device

            case "''${1:-}" in
              on) busctl call org.freedesktop.UPower "$device" "$interface" EnableChargeThreshold b true ;;
              off) busctl call org.freedesktop.UPower "$device" "$interface" EnableChargeThreshold b false ;;
              "") busctl get-property org.freedesktop.UPower "$device" "$interface" ChargeThresholdEnabled ;;
              *)
                echo "usage: charge-limit [on|off]" >&2
                exit 1
                ;;
            esac
          '';
        };
      };
    };
}

_: {
  # Expose DDC/CI external monitors as /sys/class/backlight devices so
  # brightnessctl (and brightness-control) can drive their brightness like a
  # laptop panel. The ddcci kernel driver can't auto-probe on kernel 6.8+, so
  # devices are registered by hand at boot and on every DRM hotplug.
  # Source: https://wiki.nixos.org/wiki/Backlight#DDC/CI
  flake.nixosModules.ddcci =
    {
      lib,
      pkgs,
      ...
    }:
    let
      ddcci-register = pkgs.writeShellApplication {
        name = "ddcci-register";

        runtimeInputs = [
          pkgs.coreutils # seq & sleep
          pkgs.ddcutil
          pkgs.gnugrep
        ];

        inheritPath = false;
        text = builtins.readFile ./register.sh;
      };
    in
    {
      # I2C is required for ddcutil to probe monitors over DDC/CI.
      hardware.i2c.enable = true;

      boot.extraModulePackages = with pkgs.linuxPackages; [ ddcci-driver ];
      boot.kernelModules = [ "ddcci-backlight" ];

      # Re-run registration whenever a monitor is connected or powered on: the
      # kernel emits a DRM "change" hotplug event. This replaces a one-shot udev
      # "add" rule that only fired at boot, so a monitor that was off at boot now
      # gets picked up when it comes up.
      services.udev.extraRules = ''
        SUBSYSTEM=="drm", ACTION=="change", ENV{HOTPLUG}=="1", RUN+="${pkgs.systemd}/bin/systemctl start --no-block ddcci-register.service"
      '';

      # Instantiate ddcci backlight devices for any responsive DDC/CI monitor.
      # Triggered at boot and on DRM hotplug (see the udev rule above).
      systemd.services.ddcci-register = {
        description = "Register DDC/CI monitors as backlight devices";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe ddcci-register;
        };
      };
    };
}

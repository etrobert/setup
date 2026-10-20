_: {
  flake.nixosModules.reboot-on-hang = {
    # Kernel parameters rather than sysctls so they also cover stage 1.
    boot.kernelParams = [
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "nmi_watchdog=panic"
    ];

    systemd.settings.Manager.RuntimeWatchdogSec = "30s";
  };
}

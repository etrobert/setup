# Wake tower's discrete GPU when the monitor is powered on.
#
# With no display connected, the RX 9070 XT runtime-suspends (BACO, ~1 W idle
# instead of ~10 W) — but in that state its DisplayPort hotplug detection is
# powered down too, so turning the monitor back on goes unnoticed and the
# screen stays black. The monitor's internal USB hub does enumerate on
# power-on, though, so use that as the wake signal: briefly forbid runtime PM,
# which resumes the card; the resume path re-probes connectors and the
# compositor lights the output. Runtime PM is re-allowed right after — with a
# display connected the driver keeps the card awake anyway, and on a spurious
# trigger it just re-suspends seconds later.
_: {
  flake.nixosModules.monitorGpuWake =
    let
      # The RX 9070 XT's PCI address (stable across boots, unlike DRM card
      # numbering).
      gpu = "0000:03:00.0";
    in
    {
      services.udev.extraRules = ''
        # Dell U3223QE internal USB2 hub, present only while the monitor is on.
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0424", ATTR{idProduct}=="7240", TAG+="systemd", ENV{SYSTEMD_WANTS}+="monitor-gpu-wake.service"
      '';

      systemd.services.monitor-gpu-wake = {
        description = "Wake the discrete GPU so it re-probes the monitor";

        serviceConfig.Type = "oneshot";

        script = /* bash */ ''
          echo on > /sys/bus/pci/devices/${gpu}/power/control
          sleep 1
          echo auto > /sys/bus/pci/devices/${gpu}/power/control
        '';
      };
    };
}

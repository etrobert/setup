_: {
  flake.nixosModules.monitorGpuWake =
    let
      # RX 9070 XT; PCI addresses are stable across boots, DRM card numbers are not
      gpu = "0000:03:00.0";
    in
    {
      # amdgpu cannot see a monitor power on while runtime-suspended, but the Dell's USB hub enumerates
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0424", ATTR{idProduct}=="7240", TAG+="systemd", ENV{SYSTEMD_WANTS}+="monitor-gpu-wake.service"
      '';

      systemd.services.monitor-gpu-wake = {
        description = "Wake the discrete GPU so it re-probes the monitor";
        serviceConfig.Type = "oneshot";
        # Resuming re-probes connectors; the driver stays awake while one is connected
        script = /* bash */ ''
          echo on > /sys/bus/pci/devices/${gpu}/power/control
          sleep 1
          echo auto > /sys/bus/pci/devices/${gpu}/power/control
        '';
      };
    };
}

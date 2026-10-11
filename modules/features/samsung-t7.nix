{
  flake.nixosModules.samsung-t7 = {
    # The kernel refuses TRIM to USB SSDs by default; unmap lets fstrim reach the T7.
    services.udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="scsi_disk", ATTRS{idVendor}=="04e8", ATTRS{idProduct}=="4001", ATTR{provisioning_mode}="unmap"
    '';
  };
}

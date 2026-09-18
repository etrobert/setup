{ self, inputs, ... }:

{
  flake.nixosModules.charonConfiguration = {
    imports = [
      self.nixosModules.charonHardware
      inputs.disko.nixosModules.disko
    ];

    # Hybrid BIOS/UEFI: the EF02 partition serves legacy boot, the ESP serves
    # UEFI, so the image boots whichever mode OVH's KVM uses.
    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    disko.devices.disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02";
          };
          esp = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };

    networking.hostName = "charon";

    time.timeZone = "Europe/Berlin";

    system.stateVersion = "25.11";
  };
}

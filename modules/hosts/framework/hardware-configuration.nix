{ inputs, ... }:
{
  flake.nixosModules.framework-hardware =
    { modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.disko.nixosModules.disko
      ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];

      disko.devices.disk.main = {
        # Placeholder until the machine arrives: replace with its /dev/disk/by-id path.
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "root";
                passwordFile = "/tmp/disk.key";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "/root".mountpoint = "/";
                    "/nix".mountpoint = "/nix";
                    "/home".mountpoint = "/home";
                  };
                };
              };
            };
          };
        };
      };

      nixpkgs.hostPlatform = "x86_64-linux";
    };
}

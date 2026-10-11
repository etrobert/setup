{ inputs, ... }:

{
  flake.nixosModules.charon-configuration =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.ghostty.terminfo ];

      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        inputs.disko.nixosModules.disko
      ];

      # OVH VPSes boot legacy BIOS (UEFI exists only on their FreeBSD-UEFI image):
      # https://github.com/ovh/infrastructure-roadmap/issues/377
      disko.devices.disk.main = {
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
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

      disko.devices.disk.downloads = {
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_e392dcc5-e3b3-4887-aeee-bfe892c1c1aa";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/srv/downloads";
          # slskd < 0.26.1 prunes by access time, which share rescans keep fresh: https://github.com/slskd/slskd/commit/71401118
          mountOptions = [ "noatime" ];
        };
      };

      assertions = [
        {
          assertion = lib.versionOlder config.services.slskd.package.version "0.26.1";
          message = "slskd ${config.services.slskd.package.version} prunes by write time: drop noatime from modules/hosts/charon/configuration.nix";
        }
      ];

      networking.hostName = "charon";

      time.timeZone = "Europe/Berlin";

      system.stateVersion = "25.11";
    };
}

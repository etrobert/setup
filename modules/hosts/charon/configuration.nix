{ inputs, ... }:

{
  flake.nixosModules.charonConfiguration =
    { pkgs, modulesPath, ... }:
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

      networking.hostName = "charon";

      time.timeZone = "Europe/Berlin";

      system.stateVersion = "25.11";
    };
}

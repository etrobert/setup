# Taken from nixos-generate-config runs on OVH VPSes (e.g.
# github:ironm00n/yakery hosts/ovh-vps1-1); regenerate on the box once it exists.
_: {
  flake.nixosModules.charonHardware =
    { lib, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      boot = {
        initrd.availableKernelModules = [
          "ata_piix"
          "uhci_hcd"
          "virtio_pci"
          "virtio_scsi"
          "sd_mod"
        ];
        initrd.kernelModules = [ ];
        kernelModules = [ "kvm-intel" ];
        extraModulePackages = [ ];
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}

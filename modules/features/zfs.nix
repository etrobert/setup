_: {
  flake.nixosModules.zfs = {
    boot.supportedFilesystems.zfs = true;

    networking.hostId = "cd224010";

    services.zfs.autoScrub.enable = true;
  };
}

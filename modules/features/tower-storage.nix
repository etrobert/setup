# tower's redundant data pool: 4x 1TB Crucial BX500 SATA SSDs in ZFS raidz1
# (~3TB usable, survives any one drive failure), declared with disko. Disko
# only creates — after the drives are installed, provision once with:
#   nix run github:nix-community/disko -- --mode destroy,format,mount \
#     --flake .#tower
# To add datasets or change properties later, edit here and re-run
# `disko --mode format,mount` (non-destructive: creates missing datasets,
# applies updated properties). Removing datasets is manual `zfs destroy`.
{ inputs, ... }:
{
  flake.nixosModules.towerStorage =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) ntfy-wrapped;

      # ZED's email hook: subject arrives as $1, event details on stdin.
      zed-ntfy = pkgs.writeShellApplication {
        name = "zed-ntfy";

        runtimeInputs = [ ntfy-wrapped ];

        inheritPath = false;

        text = /* bash */ ''
          ntfy publish --quiet --title "$1"
        '';
      };

      zfsDisk = id: {
        type = "disk";
        device = "/dev/disk/by-id/${id}";

        content = {
          type = "zfs";
          pool = "tank";
        };
      };
    in
    {
      imports = [ inputs.disko.nixosModules.disko ];

      disko.devices = {
        disk = {
          ssd1 = zfsDisk "ata-CT1000BX500SSD1_2337E8764F3E";
          ssd2 = zfsDisk "ata-CT1000BX500SSD1_2337E8764EDE";
          ssd3 = zfsDisk "ata-CT1000BX500SSD1_2239E66D4B8C";
          ssd4 = zfsDisk "ata-CT1000BX500SSD1_2233E656C53B";
        };

        zpool.tank = {
          type = "zpool";
          mode = "raidz1";
          mountpoint = "/tank";

          # A data pool must not block boot when absent or faulted.
          mountOptions = [ "nofail" ];

          options.ashift = "12";
          rootFsOptions.atime = "off";

          datasets.media = {
            type = "zfs_fs";
            mountpoint = "/tank/media";

            # Not inherited from the zpool-level mountOptions, which only
            # covers the pool root's own mount.
            mountOptions = [ "nofail" ];
          };
        };
      };

      boot = {
        supportedFilesystems = [ "zfs" ];
        zfs.forceImportRoot = false;
      };

      # head --bytes 8 /etc/machine-id on tower
      networking.hostId = "6b83a633";

      services = {
        zfs = {
          autoScrub.enable = true;

          zed.settings = {
            # Unused by zed-ntfy, but ZED skips the email hook entirely when
            # ZED_EMAIL_ADDR is empty.
            ZED_EMAIL_ADDR = [ "root" ];
            ZED_EMAIL_PROG = lib.getExe zed-ntfy;
            ZED_EMAIL_OPTS = "'@SUBJECT@'";

            # Also notify on healthy events (e.g. clean scrub completion), as
            # a monthly liveness check of the alert path.
            ZED_NOTIFY_VERBOSE = true;
          };
        };

        smartd.enable = true;

        sanoid = {
          enable = true;

          datasets.tank = {
            recursive = true;
            # sanoid.defaults.conf keeps 48 hourly snapshots unless overridden.
            hourly = 0;
          };
        };
      };
    };
}

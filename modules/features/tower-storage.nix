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

          # Without nofail, systemd's fstab-generator makes a mount a Requires=
          # of local-fs.target, whose OnFailure=emergency.target then drops the
          # whole boot to a rescue shell when the pool is absent or faulted.
          # Disko applies this to the pool root's own mount only, so every
          # dataset below repeats it.
          mountOptions = [ "nofail" ];

          options.ashift = "12";
          rootFsOptions.atime = "off";

          datasets = {
            media = {
              type = "zfs_fs";
              mountpoint = "/tank/media";
              mountOptions = [ "nofail" ];
            };

            postgres = {
              type = "zfs_fs";
              mountpoint = "/var/lib/postgresql";
              mountOptions = [ "nofail" ];

              # Postgres writes 8 KiB pages, so a large record turns a
              # scattered page update into a copy-on-write rewrite of the whole
              # record. On this pool's geometry fio measures 4.4x physical
              # write amplification at 16K against 17.7x at the 128K default.
              options.recordsize = "16K";
            };
          };
        };
      };

      boot = {
        supportedFilesystems = [ "zfs" ];
        zfs.forceImportRoot = false;
      };

      # head --bytes 8 /etc/machine-id on tower
      networking.hostId = "6b83a633";

      # z (adjust-if-exists), not d: with nofail mounts, a boot without the
      # pool must not create these paths as plain directories on the root
      # filesystem.
      # Requires /tank to stay root-owned (its dataset birth default):
      # tmpfiles' unsafe-path-transition guard refuses child rules under a
      # user-owned parent.
      systemd.tmpfiles.settings.tank."/tank/media".z = {
        user = "soft";
        group = "users";
        mode = "0755";
      };

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

          datasets = {
            tank = {
              recursive = true;
              # sanoid.defaults.conf keeps 48 hourly snapshots unless overridden.
              hourly = 0;
            };

            # Immich's schema migrations are one-way, so a recent rollback
            # point is the only undo available.
            "tank/postgres".hourly = 48;
          };
        };
      };
    };
}

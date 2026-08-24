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

      # smartd's mail hook: it runs `mailer -i <recipient>` with the message on
      # stdin, and SMARTD_* is inherited from the notify script that calls it.
      # head keeps the body under ntfy's 4096-byte limit; the warning comes
      # first, ahead of the `smartctl -a` dump smartd appends.
      smartd-ntfy = pkgs.writeShellApplication {
        name = "smartd-ntfy";

        runtimeInputs = [
          pkgs.coreutils
          ntfy-wrapped
        ];

        inheritPath = false;

        text = /* bash */ ''
          head --bytes 4000 |
            ntfy publish --quiet --title "$SMARTD_SUBJECT"
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

            photos = {
              type = "zfs_fs";
              mountpoint = "/tank/photos";
              mountOptions = [ "nofail" ];
            };

            postgres = {
              type = "zfs_fs";
              mountpoint = "/var/lib/postgresql";
              mountOptions = [ "nofail" ];

              # Postgres writes 8 KiB pages, so a large record turns a
              # scattered page update into a copy-on-write rewrite of the whole
              # record.
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

      systemd = {
        # z (adjust-if-exists), not d: with nofail mounts, a boot without the
        # pool must not create this path as a plain directory on the root
        # filesystem.
        # Requires /tank to stay root-owned (its dataset birth default):
        # tmpfiles' unsafe-path-transition guard refuses child rules under a
        # user-owned parent.
        tmpfiles.settings.tank."/tank/media".z = {
          user = "soft";
          group = "users";
          mode = "0755";
        };

        services = {
          # `zfs mount -a` races systemd's fstab units for the disko-managed
          # datasets, failing the mount unit and every service requiring it.
          # Masked, not unwanted: zfs-share.service pulls it back in via Wants=.
          zfs-mount.enable = false;

          # sanoid's ExecStartPre delegates permissions with `zfs allow`, a
          # sync task that cannot return until the open txg commits. A
          # write-heavy pool pushes txg sync past systemd's 90s default, so the
          # unit fails on the delegation rather than on anything sanoid did.
          sanoid.serviceConfig.TimeoutStartSec = "15min";
        };
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

        smartd = {
          enable = true;

          # Only `wall` is on by default, which reaches attached ttys and
          # nothing else, so a prefail warning goes unseen. The mail hook is
          # the module's only exec path out.
          notifications.mail = {
            enable = true;
            mailer = lib.getExe smartd-ntfy;
          };
        };

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

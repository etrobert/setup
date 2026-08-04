# Nightly restic backup of the data that cannot be regenerated, to pi over
# SFTP. Failures alert through the global OnFailure drop-in in
# ntfy-failure-alerts.
#
# Runs as soft rather than root so it can reuse soft's existing passphraseless
# key to pi; the trade-off is that root-owned service state under /var/lib
# (Home Assistant history, Navidrome, PostgreSQL) is not covered yet.
_: {
  flake.nixosModules.restic =
    { config, ... }:
    {
      # Readable by soft because the backup runs as soft, not root.
      age.secrets.restic-password = {
        file = ../../secrets/restic-password.age;
        owner = "soft";
      };

      services.restic.backups.tower = {
        user = "soft";
        repository = "sftp:soft@pi:/home/soft/restic";
        passwordFile = config.age.secrets.restic-password.path;
        initialize = true;

        extraOptions = [
          "sftp.command='ssh soft@pi -i /home/soft/.ssh/id_ed25519 -s sftp'"
        ];

        paths = [
          "/home/soft/.ssh"
          "/home/soft/sync"
          "/home/soft/work"
          "/srv/files"
        ];

        # temp/ is the auto-expiring drop zone; the rest are upstream clones
        # that re-fetch faster than they restore.
        exclude = [
          "/srv/files/temp"
          "/home/soft/work/nixpkgs"
          "/home/soft/work/qmk_firmware"
          "**/node_modules"
        ];

        timerConfig.OnCalendar = "daily";

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
        ];
      };
    };
}

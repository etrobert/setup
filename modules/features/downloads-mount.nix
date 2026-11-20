_: {
  flake.nixosModules.downloads-mount = _: {
    fileSystems."/mnt/downloads" = {
      device = "soft@51.91.29.38:/storage/downloads";
      fsType = "sshfs";
      options = [
        # Mounted on first access, so a boot never waits on the link.
        "x-systemd.automount"
        "_netdev"
        # Radarr and beets run as their own users.
        "allow_other"
        # Imports copy out; nothing here deletes the download host's files.
        "ro"
        "reconnect"
        "ServerAliveInterval=15"
        # soft: the key the download host accepts.
        "IdentityFile=/home/soft/.ssh/id_ed25519"
      ];
    };

    # Five failed mounts in a row otherwise fail the automount until a manual reset.
    systemd.units."mnt-downloads.mount" = {
      overrideStrategy = "asDropin";
      text = ''
        [Unit]
        StartLimitIntervalSec=0
      '';
    };
  };
}

# tower's tank share, mounted at /mnt/tank on first access and unmounted
# after a minute idle, so neither boot nor suspend depends on tower being
# reachable.
_: {
  flake.nixosModules.tankMount =
    { config, ... }:
    {
      age.secrets.smb-credentials.file = ../../secrets/smb-credentials.age;

      fileSystems."/mnt/tank" = {
        device = "//tower/tank";
        fsType = "cifs";

        options = [
          "credentials=${config.age.secrets.smb-credentials.path}"
          "uid=soft"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
        ];
      };
    };
}

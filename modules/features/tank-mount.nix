# tower's tank share, mounted at /mnt/tank on first access so boot never
# depends on tower being reachable.
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
        ];
      };
    };
}

# tower's tank share, mounted at /mnt/tank on first access and unmounted
# after a minute idle, so neither boot nor suspend depends on tower being
# reachable.
_: {
  flake.nixosModules.tank-mount =
    { config, ... }:
    {
      sops.secrets.smb-password.sopsFile = ../../secrets/linux-workstations.yaml;

      sops.templates.smb-credentials.content = ''
        username=soft
        password=${config.sops.placeholder.smb-password}
      '';

      fileSystems."/mnt/tank" = {
        device = "//tower/tank";
        fsType = "cifs";

        options = [
          "credentials=${config.sops.templates.smb-credentials.path}"
          "uid=soft"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
        ];
      };
    };
}

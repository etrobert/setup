# tower's tank share, mounted at /mnt/tank on first access and unmounted
# after a minute idle, so neither boot nor suspend depends on tower being
# reachable.
_: {
  flake.nixosModules.tankMount =
    { config, lib, ... }:
    {
      # The switch tank guard (pkgs/switch.nix) works around systemd freezing
      # PID 1 when it re-execs with this mount stale (NixOS/nixpkgs#375376,
      # systemd/systemd#39354), audited against systemd 261. On the bump past
      # it, re-check those issues: if fixed, drop the guard and this assertion;
      # otherwise raise the bound.
      assertions = [
        {
          assertion = lib.versionOlder config.systemd.package.version "262";
          message = "systemd ${config.systemd.package.version} exceeds the version the switch tank guard was audited against — see the comment in modules/features/tank-mount.nix";
        }
      ];

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

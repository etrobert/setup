# Redundant storage on tower: 4x 1 TB SATA SSDs in a ZFS raidz2 pool named
# "tank". The pool is created once by hand with `zpool create` (commands in
# the PR that introduced this file); NixOS only imports it. Datasets carry
# ZFS-native mountpoints, so no fileSystems entries are needed.
_: {
  flake.nixosModules.towerStorage =
    {
      self,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) ntfy-wrapped;

      # ZED invokes this as its "email" program: subject as $1 (per
      # ZED_EMAIL_OPTS below), body on stdin.
      zed-ntfy = pkgs.writeShellApplication {
        name = "zed-ntfy";
        inheritPath = false;
        runtimeInputs = [ ntfy-wrapped ];
        text = /* bash */ ''
          ntfy publish --quiet --title "$1"
        '';
      };
    in
    {
      networking.hostId = "6b83a633";

      boot.supportedFilesystems.zfs = true;

      boot.zfs = {
        extraPools = [ "tank" ];
        forceImportRoot = false;
      };

      services = {
        zfs = {
          autoScrub = {
            enable = true;
            interval = "monthly";
          };

          zed.settings = {
            ZED_EMAIL_ADDR = [ "root" ];
            ZED_EMAIL_PROG = lib.getExe zed-ntfy;
            ZED_EMAIL_OPTS = "'@SUBJECT@'";
            ZED_NOTIFY_VERBOSE = true;
          };
        };

        smartd.enable = true;

        sanoid = {
          enable = true;

          datasets.tank = {
            recursive = true;
            autosnap = true;
            autoprune = true;
            daily = 7;
            weekly = 4;
            monthly = 3;
          };
        };
      };
    };
}

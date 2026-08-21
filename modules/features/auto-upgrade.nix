_: {
  flake.nixosModules.autoUpgrade =
    {
      self,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) deploy-gate;
    in
    {
      system.autoUpgrade = {
        enable = true;
        flake = "github:etrobert/setup/deploy#pi";
        flags = [
          "--accept-flake-config"
          "--print-build-logs"
        ];
        dates = "*:0/1"; # every minute
        allowReboot = true;
      };

      # StateDirectory= exports $STATE_DIRECTORY to every Exec* line, including
      # the ExecCondition and ExecStopPost the gate runs in.
      systemd.services.nixos-upgrade.environment.DEPLOY_URL = "https://github.com/etrobert/setup.git";

      systemd.services.nixos-upgrade.serviceConfig = {
        StateDirectory = "nixos-upgrade";
        ExecCondition = "${lib.getExe deploy-gate} check";

        # A failed switch whose ntfy alert also failed stays pinned in memory,
        # so systemd-run refuses the next run of nixos-rebuild's fixed-name
        # transient unit: "already loaded or has a fragment file".
        ExecStartPre = "-${pkgs.systemd}/bin/systemctl reset-failed nixos-rebuild-switch-to-configuration.service";

        # On stop rather than on success: a rev that fails to build or switch
        # must still be recorded, or the gate re-offers it every minute forever.
        ExecStopPost = "${lib.getExe deploy-gate} record";
      };
    };
}

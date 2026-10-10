{ self, ... }:
{
  flake.nixosModules.auto-upgrade =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      deployGate = pkgs.writeShellApplication {
        name = "deploy-gate";

        runtimeInputs = [
          pkgs.gitMinimal
          pkgs.coreutils
        ];

        inheritPath = false;

        text = ''
          state_dir=/var/lib/nixos-upgrade
          failed_rev="$state_dir/last-failed-rev"
          pending_rev="$state_dir/pending-rev"
          deploy_url=https://github.com/etrobert/setup.git

          # The gate is part of the running system, so this is the running revision.
          running=${config.system.configurationRevision}

          case "$1" in
            check)
              if [ -e /run/systemd/shutdown/scheduled ]; then
                echo "reboot into a new system already scheduled; skipping"
                exit 1
              fi
              rev=$(git ls-remote "$deploy_url" deploy | cut --fields=1)
              if [ -z "$rev" ]; then
                echo "could not resolve deploy ref; skipping" >&2
                exit 1
              fi
              if [ "$rev" = "$running" ]; then
                echo "already running deploy $rev"
                exit 1
              fi
              if [ -f "$failed_rev" ] && [ "$rev" = "$(cat "$failed_rev")" ]; then
                echo "deploy $rev already failed; skipping"
                exit 1
              fi
              printf '%s\n' "$rev" > "$pending_rev"
              echo "running $running, deploy is $rev; upgrading"
              ;;
            record)
              if [ ! -f "$pending_rev" ]; then
                exit 0
              fi
              if [ "$SERVICE_RESULT" = success ]; then
                rm "$pending_rev"
              else
                mv "$pending_rev" "$failed_rev"
              fi
              ;;
            *)
              echo "usage: deploy-gate {check|record}" >&2
              exit 2
              ;;
          esac
        '';
      };
    in
    {
      system.configurationRevision = self.rev or self.dirtyRev;

      system.autoUpgrade = {
        enable = true;
        flake = "github:etrobert/setup/deploy#${config.networking.hostName}";
        # --upgrade only updates channels; nixos-rebuild warns on every run.
        upgrade = false;
        flags = [
          "--accept-flake-config"
          "--print-build-logs"
        ];
        dates = "*:0/1"; # every minute
        allowReboot = lib.mkDefault true;
      };

      systemd.services.nixos-upgrade = {
        unitConfig = {
          ConditionPathExists = "!/var/lib/nixos-upgrade/paused";
          ConditionACPower = true;
        };

        serviceConfig = {
          StateDirectory = "nixos-upgrade";
          ExecCondition = "${lib.getExe deployGate} check";

          # A failed switch whose ntfy alert also failed stays pinned in memory,
          # so systemd-run refuses the next run of nixos-rebuild's fixed-name
          # transient unit: "already loaded or has a fragment file".
          ExecStartPre = "-${pkgs.systemd}/bin/systemctl reset-failed nixos-rebuild-switch-to-configuration.service";

          ExecStopPost = "${lib.getExe deployGate} record";
        };
      };
    };
}

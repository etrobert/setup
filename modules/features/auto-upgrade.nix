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
          # The gate is part of the running system, so this is the running revision.
          running=${config.system.configurationRevision}

          if [ -e /run/systemd/shutdown/scheduled ]; then
            echo "reboot into a new system already scheduled; skipping"
            exit 1
          fi
          rev=$(git ls-remote https://github.com/etrobert/setup.git deploy | cut --fields=1)
          if [ -z "$rev" ]; then
            echo "could not resolve deploy ref; skipping" >&2
            exit 1
          fi
          if [ "$rev" = "$running" ]; then
            echo "already running deploy $rev"
            exit 1
          fi
          echo "running $running, deploy is $rev; upgrading"
        '';
      };

      kernelNotice = pkgs.writeShellApplication {
        name = "kernel-notice";

        runtimeInputs = [
          pkgs.coreutils
          self.packages.${pkgs.stdenv.hostPlatform.system}.ntfy-wrapped
        ];

        inheritPath = false;

        text = ''
          before=/var/lib/nixos-upgrade/kernel-before

          kernel() {
            readlink /run/current-system/{initrd,kernel,kernel-modules}
          }

          case "$1" in
            before)
              kernel > "$before"
              ;;
            after)
              if [ "$(kernel)" != "$(cat "$before")" ]; then
                ntfy publish ${lib.escapeShellArg "${config.networking.hostName}: new kernel, reboot when convenient"}
              fi
              ;;
            *)
              echo "usage: kernel-notice {before|after}" >&2
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
          ExecCondition = lib.getExe deployGate;

          # A failed switch whose ntfy alert also failed stays pinned in memory,
          # so systemd-run refuses the next run of nixos-rebuild's fixed-name
          # transient unit: "already loaded or has a fragment file".
          ExecStartPre = [
            "-${pkgs.systemd}/bin/systemctl reset-failed nixos-rebuild-switch-to-configuration.service"
          ]
          ++ lib.optional (!config.system.autoUpgrade.allowReboot) "${lib.getExe kernelNotice} before";

          ExecStartPost = lib.mkIf (
            !config.system.autoUpgrade.allowReboot
          ) "${lib.getExe kernelNotice} after";
        };
      };
    };
}

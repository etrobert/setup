_: {
  flake.nixosModules.autoUpgrade =
    { pkgs, lib, ... }:
    let
      deployGate = pkgs.writeShellApplication {
        name = "deploy-gate";

        runtimeInputs = [
          pkgs.gitMinimal
          pkgs.coreutils
        ];

        inheritPath = false;

        text = /* bash */ ''
          state_dir=/var/lib/nixos-upgrade
          last_rev="$state_dir/last-attempted-rev"
          pending_rev="$state_dir/pending-rev"
          deploy_url=https://github.com/etrobert/setup.git

          case "$1" in
            check)
              rev=$(git ls-remote "$deploy_url" deploy | cut --fields=1)
              if [ -z "$rev" ]; then
                echo "could not resolve deploy ref; skipping" >&2
                exit 1
              fi
              if [ -f "$last_rev" ] && [ "$rev" = "$(cat "$last_rev")" ]; then
                echo "deploy $rev already attempted; skipping"
                exit 1
              fi
              printf '%s\n' "$rev" > "$pending_rev"
              echo "deploy $rev differs from last attempt; upgrading"
              ;;
            record)
              if [ -f "$pending_rev" ]; then
                mv "$pending_rev" "$last_rev"
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

      systemd.services.nixos-upgrade.serviceConfig = {
        StateDirectory = "nixos-upgrade";
        ExecCondition = "${lib.getExe deployGate} check";

        # A failed switch whose ntfy alert also failed stays pinned in memory,
        # so systemd-run refuses the next run of nixos-rebuild's fixed-name
        # transient unit: "already loaded or has a fragment file".
        ExecStartPre = "-${pkgs.systemd}/bin/systemctl reset-failed nixos-rebuild-switch-to-configuration.service";

        # On stop rather than on success: a rev that fails to build or switch
        # must still be recorded, or the gate re-offers it every minute forever.
        ExecStopPost = "${lib.getExe deployGate} record";
      };
    };
}

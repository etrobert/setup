# EndeavourOS-style update notifier: interactive hosts don't auto-upgrade
# (that's pi's autoUpgrade module) — instead a timer compares the rev this
# system was built from against the pushed `deploy` ref and posts one ntfy
# notification per deploy rev the host isn't running. Rebuilding stays a
# human decision.
_: {
  flake.nixosModules.updateNotifier =
    {
      self,
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) ntfy-wrapped;

      # The rev this generation was built from, baked in at eval time — after a
      # switch the timer runs the new generation's script, so this tracks the
      # running system without any runtime introspection. A dirty tree still
      # identifies its base commit (a locally-patched build of the deploy rev
      # isn't "behind"); a rev-less tree (tarball fetch) falls back to
      # "unknown", which never matches and degrades to one notification per
      # deploy rev.
      runningRev = self.rev or (lib.removeSuffix "-dirty" (self.dirtyRev or "unknown"));

      updateCheck = pkgs.writeShellApplication {
        name = "update-check";

        runtimeInputs = [
          pkgs.gitMinimal
          pkgs.coreutils
          ntfy-wrapped
        ];

        inheritPath = false;

        text = ''
          notified="$STATE_DIRECTORY/notified-rev"
          deploy_url=https://github.com/etrobert/setup.git
          running_rev=${lib.escapeShellArg runningRev}

          # Offline is a skip, not a failure: leod roams, and a failed unit
          # would trip the ntfyFailureAlerts drop-in on every flaky network.
          deploy_rev=$(git ls-remote "$deploy_url" deploy | cut --fields=1 || true)
          if [ -z "$deploy_rev" ]; then
            echo "could not resolve deploy ref (offline?); skipping"
            exit 0
          fi

          if [ "$deploy_rev" = "$running_rev" ]; then
            echo "running deploy $deploy_rev; up to date"
            exit 0
          fi

          if [ -f "$notified" ] && [ "$deploy_rev" = "$(cat "$notified")" ]; then
            echo "already notified about deploy $deploy_rev; skipping"
            exit 0
          fi

          ntfy publish --quiet \
            --title "${config.networking.hostName} is behind deploy" \
            "running ''${running_rev:0:7}, deploy at ''${deploy_rev:0:7}"
          printf '%s\n' "$deploy_rev" > "$notified"
        '';
      };
    in
    {
      systemd.services.update-notifier = {
        description = "Notify when this host falls behind the deploy ref";
        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "update-notifier";
          ExecStart = lib.getExe updateCheck;
        };
      };

      systemd.timers.update-notifier = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "10min";
          OnUnitActiveSec = "1h";
        };
      };
    };
}

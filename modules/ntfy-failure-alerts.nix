# Alert on any systemd service failure: a top-level drop-in (service.d/)
# attaches OnFailure=ntfy-failure@<unit>.service to every system service, and
# the template posts the failing unit's recent journal to the ntfy topic (via
# ntfy-wrapped). Delivery is best-effort — no rate limiting and no retry; an
# undelivered alert only leaves a failed ntfy-failure@ instance
# (systemctl --failed).
_: {
  flake.nixosModules.ntfyFailureAlerts =
    {
      self,
      config,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) ntfy-wrapped;
    in
    {
      # Shipped as a package because /etc/systemd/system is a generated
      # symlink tree — NixOS has no option for type-level (service.d/)
      # drop-ins.
      systemd.packages = [
        (pkgs.linkFarm "ntfy-failure-alert-dropins" {
          "etc/systemd/system/service.d/10-ntfy-failure.conf" = pkgs.writeText "10-ntfy-failure.conf" ''
            [Unit]
            OnFailure=ntfy-failure@%n.service
          '';

          # Loop prevention: OnFailure= cannot be reset once added
          # (systemd.unit(5): dependencies cannot be reset to an empty
          # list), but a same-named drop-in in the more specific directory
          # masks the service.d/ one — so alert instances get no OnFailure
          # and a failed alert (e.g. tower unreachable) cannot trigger
          # itself.
          "etc/systemd/system/ntfy-failure@.service.d/10-ntfy-failure.conf" =
            pkgs.writeText "10-ntfy-failure-mask.conf" ''
              [Unit]
            '';
        })
      ];

      systemd.services."ntfy-failure@" = {
        description = "ntfy alert for failed unit %i";
        scriptArgs = "%i";
        path = [ ntfy-wrapped ];

        # tail keeps the body under ntfy's 4096-byte message limit.
        # ntfy-wrapped supplies the endpoint (NTFY_TOPIC), so it isn't named
        # here; --quiet is silent on success but still prints server errors.
        script = /* bash */ ''
          journalctl --unit "$1" --lines 15 --no-pager |
            tail --bytes 4000 |
            ntfy publish --quiet --title "$1 failed on ${config.networking.hostName}"
        '';

        serviceConfig.Type = "oneshot";
      };
    };
}

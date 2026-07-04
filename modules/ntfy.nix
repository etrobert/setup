# Self-hosted ntfy notification bus.
#
# - `ntfy` (server): runs ntfy on tower, reachable only over Tailscale (the
#   port is opened on tailscale0 only — never the LAN or WAN).
# - `ntfyDesktop` (subscriber): a Linux user service that subscribes to the
#   topic and surfaces each message as a mako desktop notification.
#
# No Home Assistant wiring here — this is just the transport. Test with:
#   ntfy publish "hello"
_:
let
  host = "tower";
  port = 2586;
  topic = "home";
  url = "http://${host}:${toString port}";
in
{
  flake = {
    nixosModules = {
      ntfy = _: {
        services.ntfy-sh = {
          enable = true;
          settings = {
            base-url = url;
            listen-http = ":${toString port}";

            # iOS forbids the long-lived background connection ntfy uses on
            # Android, so the only way to wake the iOS app is Apple's push service
            # (APNs) — which only ntfy.sh's infrastructure can reach. Forward a
            # content-free poll request to ntfy.sh so it relays an APNs wake to the
            # phone, which then fetches the real message from us over Tailscale.
            # The upstream sees only a SHA-256 of the topic URL and the message ID
            # (body is a generic "New message") — never our titles, bodies, or
            # attachments. Free tier (~250 msg/day) is ample for personal use.
            upstream-base-url = "https://ntfy.sh";
          };
        };

        # Expose ntfy to the tailnet only. Within the tailnet topics are open
        # (no auth), which is acceptable for personal use.
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
      };

      # Alert on any systemd service failure: a top-level drop-in (service.d/)
      # attaches OnFailure=ntfy-failure@<unit>.service to every system service,
      # and the template posts the failing unit's recent journal to the topic.
      ntfyFailureAlerts =
        { config, pkgs, ... }:
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
            path = [ pkgs.curl ];

            # tail keeps the body under ntfy's 4096-byte message limit.
            script = /* bash */ ''
              journalctl --unit "$1" --lines 15 --no-pager |
                tail --bytes 4000 |
                curl --silent --show-error --max-time 10 \
                  --header "Title: $1 failed on ${config.networking.hostName}" \
                  --data-binary @- \
                  "${url}/${topic}"
            '';

            serviceConfig.Type = "oneshot";
          };
        };

      ntfyDesktop =
        {
          pkgs,
          lib,
          ...
        }:
        let
          # Turn an ntfy message into a desktop notification. ntfy passes the
          # message fields in via the environment when it runs this per message.
          ntfyNotify = pkgs.writeShellScript "ntfy-notify" ''
            exec ${pkgs.libnotify}/bin/notify-send -- "''${title:-Notification}" "$message"
          '';
        in
        {
          # The interactive ntfy CLI (with endpoint pre-set) comes from
          # ntfy-wrapped in base.nix — not installed here to avoid a collision.

          systemd.user.services.ntfy-notify = {
            description = "Desktop notifications from ntfy";
            partOf = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              ExecStart = "${lib.getExe pkgs.ntfy-sh} subscribe ${url}/${topic} ${ntfyNotify}";
              Restart = "always";
              RestartSec = 10;
            };
          };
        };
    };

    # macOS counterpart of ntfyDesktop: a launchd user agent that subscribes to
    # the same topic and posts each message to Notification Center via osascript
    # (matching pkgs/claude-code-wrapped/claude-rate-limit-notify.nix).
    darwinModules.ntfyDesktop =
      { lib, pkgs, ... }:
      let
        ntfyNotify = pkgs.writeShellScript "ntfy-notify" ''
          # Pass title/body as argv so quotes/backslashes/newlines in the ntfy
          # message can't break or inject into the AppleScript.
          /usr/bin/osascript \
            -e 'on run argv' \
            -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
            -e 'end run' \
            "''${title:-Notification}" "$message"
        '';
      in
      {
        # The interactive ntfy CLI (with endpoint pre-set) comes from
        # ntfy-wrapped in base.nix — not installed here to avoid a collision.

        launchd.user.agents.ntfy-notify = {
          serviceConfig = {
            ProgramArguments = [
              (lib.getExe pkgs.ntfy-sh)
              "subscribe"
              "${url}/${topic}"
              "${ntfyNotify}"
            ];
            KeepAlive = true;
            RunAtLoad = true;
          };
        };
      };
  };
}

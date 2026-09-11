# Self-hosted ntfy notification bus.
#
# - `ntfy` (server): runs ntfy on tower, reachable only over Tailscale (the
#   port is opened on tailscale0 only — never the LAN or WAN).
# - `ntfyDesktop` (subscriber): a Linux user service that subscribes to the
#   topic and surfaces each message as a desktop notification.
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
    nixosModules.ntfy = _: {
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

      services.tsnsrv.services.ntfy.toURL = "http://127.0.0.1:${toString port}";
    };

    nixosModules.ntfyDesktop =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        # Turn an ntfy message into a desktop notification. ntfy passes the
        # message fields in via the environment when it runs this per message,
        # but only as title/message/priority/tags — an action's URL is
        # reachable only through the raw JSON.
        ntfyNotify = pkgs.writeShellApplication {
          name = "ntfy-notify";

          runtimeInputs = [
            pkgs.curl
            pkgs.jq
            pkgs.libnotify
            pkgs.xdg-utils
          ];

          # Deliberately not false: xdg-open resolves the browser through
          # PATH, which the unit supplies below.
          inheritPath = true;

          text = ''
            # Supplied per message by ntfy; ''${title} has a default below.
            raw=''${raw:?not set by ntfy}
            message=''${message:?not set by ntfy}
            id=''${id:?not set by ntfy}

            # An action's URL, else the message's click URL: Miniflux's pushes
            # and `ntfy publish --click` carry the latter.
            url=$(jq --raw-output 'first(.actions[]? | .url) // .click // empty' <<<"$raw")

            # notify-send takes a local path, so an attachment has to be
            # fetched. Named per message, because several can arrive at once
            # and would otherwise race on one path. The daemon reads the file
            # after this handler returns, so it cannot be deleted here. They
            # are a few KB in tmpfs, cleared when the session ends.
            icon=()
            attachment=$(jq --raw-output '.attachment.url // empty' <<<"$raw")
            if [ -n "$attachment" ]; then
              photo="$XDG_RUNTIME_DIR/ntfy-notify-$id"
              if curl --silent --fail --max-time 15 --output "$photo" "$attachment"; then
                icon=(--icon "$photo")
                # The icon is too small to read; a click opens it full size.
                url=''${url:-$photo}
              fi
            fi

            if [ -z "$url" ]; then
              exec notify-send "''${icon[@]}" -- "''${title:-Notification}" "$message"
            fi

            # The `default` action is the one the daemon fires on a click on
            # the notification itself, so the link opens without a button hunt;
            # notify-send prints the invoked action's name.
            #
            # --action implies --wait: this blocks until the notification is
            # answered, so it runs in the background, or one left unattended
            # would stall every message behind it.
            open_on_click() {
              local action
              # errexit ends the subshell on a failed notify-send: nothing opens.
              action=$(notify-send --action default=Open "''${icon[@]}" -- \
                "''${title:-Notification}" "$message")
              if [ "$action" = default ]; then
                xdg-open "$url"
              fi
            }
            open_on_click &
          '';
        };
      in
      {
        # The interactive ntfy CLI (with endpoint pre-set) comes from
        # ntfy-wrapped in base.nix — not installed here to avoid a collision.

        systemd.user.services.ntfy-notify = {
          description = "Desktop notifications from ntfy";

          # xdg-open only hands the URL over; it needs a browser on PATH to
          # hand it to, and the user manager's default PATH has none.
          path = [ config.system.path ];

          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.ntfy-sh} subscribe ${url}/${topic} ${lib.getExe ntfyNotify}";
            Restart = "always";
            RestartSec = 10;
          };
        };
      };

    # macOS counterpart of ntfyDesktop: a launchd user agent that subscribes to
    # the same topic and posts each message to Notification Center via osascript
    # (matching modules/pkgs/claude-code-wrapped/_scripts/claude-rate-limit-notify.nix).
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

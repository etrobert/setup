# Self-hosted ntfy notification bus.
#
# - `ntfy` (server): runs ntfy on tower, reachable only over Tailscale (the
#   port is opened on tailscale0 only — never the LAN or WAN).
# - `ntfyDesktop` (subscriber): a Linux user service that subscribes to the
#   topic and surfaces each message as a mako desktop notification.
#
# No Home Assistant wiring here — this is just the transport. Test with:
#   curl -d "hello" http://tower:2586/home
_:
let
  host = "tower";
  port = 2586;
  topic = "home";
  url = "http://${host}:${toString port}";
in
{
  flake.nixosModules.ntfy = _: {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = url;
        listen-http = ":${toString port}";
      };
    };

    # Expose ntfy to the tailnet only. Within the tailnet topics are open
    # (no auth), which is acceptable for personal use.
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
  };

  flake.nixosModules.ntfyDesktop =
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
      # ntfy CLI for manual publish/subscribe.
      environment.systemPackages = [ pkgs.ntfy-sh ];

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

  # macOS counterpart of ntfyDesktop: a launchd user agent that subscribes to
  # the same topic and posts each message to Notification Center via osascript
  # (matching pkgs/claude-code-wrapped/claude-rate-limit-notify.nix).
  #
  # The ntfy CLI comes from Homebrew because nixpkgs' ntfy-sh currently fails
  # to build on darwin (undefined maybeRunAsService / sigHandlerConfigReload).
  # TODO: switch back to pkgs.ntfy-sh (environment.systemPackages) once the
  # darwin build is fixed.
  flake.darwinModules.ntfyDesktop =
    { pkgs, ... }:
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
      # Apple Silicon Homebrew prefix.
      ntfy = "/opt/homebrew/bin/ntfy";
    in
    {
      homebrew.brews = [ "ntfy" ];

      launchd.user.agents.ntfy-notify = {
        serviceConfig = {
          ProgramArguments = [
            ntfy
            "subscribe"
            "${url}/${topic}"
            "${ntfyNotify}"
          ];
          KeepAlive = true;
          RunAtLoad = true;
        };
      };
    };
}

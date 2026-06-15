# Keep a Claude usage "session" always ticking over on tower.
#
# Claude Pro/Max meter usage in 5-hour sessions: the session is a fixed block
# anchored to your *first* message and resets exactly 5h later, with a single
# reset time (https://support.claude.com/en/articles/11647753, and the
# product's "5-hour limit reached - resets [time]" error). A message sent while
# a session is already open just spends that session — it does not start a new
# one.
#
# Consequence: if you only ever start a session by happening to message after
# the previous one expired, you under-trigger sessions and can sit blocked on
# the 5h cap while weekly budget goes unused. Firing a trivial warmup at fixed
# times keeps fresh sessions starting on a predictable phase, so whenever you
# sit down a reset is never far off, and more of the weekly budget becomes
# reachable on 5h-bound weeks.
#
# The warmup runs as `soft` so it picks up the wrapped claude's baked-in
# CLAUDE_CONFIG_DIR (=$HOME/setup/...) and its auto-refreshing OAuth token — no
# credential wiring here. It uses Haiku because the 5h session is shared across
# all models, so the cheapest model anchors the same window for the least cost
# against the weekly cap.
#
# CAVEAT: this only *helps* while the weekly cap is slack. In a week where
# weekly is the binding limit, the extra warmups are pure waste — disable then.
{ self, ... }:
{
  flake.nixosModules.claudeWarmup =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.services.claude-warmup;
      inherit (pkgs.stdenv.hostPlatform) system;
      claude = lib.getExe self.packages.${system}.claude-code-wrapped;
    in
    {
      options.services.claude-warmup = {
        enable = lib.mkEnableOption "the Claude 5-hour session warmup timer";

        user = lib.mkOption {
          type = lib.types.str;
          default = "soft";
          description = "User to run the warmup as (owns the Claude credentials).";
        };

        onCalendar = lib.mkOption {
          type = lib.types.str;
          default = "*-*-* 08,13,18,23:00:00";
          description = ''
            systemd OnCalendar expression for warmup times. Default anchors
            sessions so resets land at predictable hours; 24h is not divisible
            by 5, so there is one longer gap overnight (acceptable while asleep).
          '';
        };

        model = lib.mkOption {
          type = lib.types.str;
          default = "claude-haiku-4-5-20251001";
          description = "Model used for the warmup ping (cheapest anchors the same session).";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.claude-warmup = {
          description = "Anchor a fresh Claude 5-hour usage session";
          # git is referenced by the wrapped claude for repo context; a neutral
          # working dir keeps it from scanning a large checkout.
          path = [ pkgs.git ];
          serviceConfig = {
            Type = "oneshot";
            User = cfg.user;
            WorkingDirectory = "/home/${cfg.user}";
            ExecStart = "${claude} --print --model ${cfg.model} hi";
            # Network may be flaky / token refresh may blip; one retry is enough.
            Restart = "on-failure";
            RestartSec = 30;
            # oneshot units can't Restart= without this.
            RestartMode = "direct";
          };
        };

        systemd.timers.claude-warmup = {
          description = "Schedule the Claude 5-hour session warmup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.onCalendar;
            # Catch up after downtime so a missed slot still anchors a session.
            Persistent = true;
          };
        };
      };
    };
}

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
      inherit (pkgs.stdenv.hostPlatform) system;
      claude = lib.getExe self.packages.${system}.claude-code-wrapped;

      # Run as the user who owns the Claude credentials. A system service (not a
      # user service) so it fires unattended regardless of login state, without
      # needing `loginctl enable-linger` — the warmup needs no user session.
      user = "soft";
      # Cheapest model: the 5h session is shared across models, so Haiku anchors
      # the same window for the least cost against the weekly cap.
      model = "claude-haiku-4-5-20251001";
      # Fixed anchors so resets land at predictable hours. Stops at 18:00 (whose
      # session runs to 23:00) — no late-night warmup, since coding past then
      # anchors a fresh session on its own.
      onCalendar = "*-*-* 08,13,18:00:00";
    in
    {
      options.services.claude-warmup.enable = lib.mkEnableOption "the Claude 5-hour session warmup timer";

      config = lib.mkIf config.services.claude-warmup.enable {
        systemd.services.claude-warmup = {
          description = "Anchor a fresh Claude 5-hour usage session";
          # git is referenced by the wrapped claude for repo context; a neutral
          # working dir keeps it from scanning a large checkout.
          path = [ pkgs.git ];
          serviceConfig = {
            Type = "oneshot";
            User = user;
            WorkingDirectory = "/home/${user}";
            ExecStart = "${claude} --print --model ${model} hi";
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
            OnCalendar = onCalendar;
            # Catch up after downtime: fires once on boot if any slot was missed
            # (systemd coalesces missed runs into a single catch-up trigger).
            Persistent = true;
          };
        };
      };
    };
}

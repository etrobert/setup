{
  wrapPackage,
  callPackage,
  claude-code,
  hass-cli-wrapped,
  lib,
  ntfy-wrapped,
  extraEnv ? { },
  readTokenFromAgenix ? false,
  # Name of the installed binary. Variants override this (e.g. "claude-copilot")
  # so they can be installed alongside the base "claude" without colliding.
  binName ? "claude",
}:
let
  statuslineScript = callPackage ./claude-plan-usage.nix { };
  formatFileScript = callPackage ./format-file.nix { };
  rateLimitNotifyScript = callPackage ./claude-rate-limit-notify.nix { ntfy-sh = ntfy-wrapped; };
  sessionHostScript = callPackage ./claude-session-host.nix { };
  ttsBackends = [ (callPackage ./tts-say.nix { }) ];
  speakScript = callPackage ./speak.nix { inherit ttsBackends; };
  runtimeInputs = [
    statuslineScript
    formatFileScript
    rateLimitNotifyScript
    sessionHostScript
    speakScript
    hass-cli-wrapped
  ]
  ++ ttsBackends;
  agenixTokenRun = lib.optional readTokenFromAgenix ''export ANTHROPIC_AUTH_TOKEN="$(cat /run/agenix/z-ai-auth-token 2>/dev/null || true)"'';
in
wrapPackage {
  package = claude-code;
  # Variants (e.g. claude-glm, claude-copilot) get renamed before wrapping;
  # the default "claude" matches the package's mainProgram, so it's a no-op.
  inherit binName;
  inheritPath = true;
  env = {
    CLAUDE_CODE_NO_FLICKER = "1";
    GIT_CONFIG_COUNT = "1";
    GIT_CONFIG_KEY_0 = "include.path";
    GIT_CONFIG_VALUE_0 = toString ./gitconfig-bot;
  }
  // extraEnv;
  run = [
    ''export CLAUDE_CONFIG_DIR="$HOME/setup/pkgs/claude-code-wrapped/config"''
    ''export GITHUB_TOKEN="$(cat /run/agenix/github-bot-token 2>/dev/null || true)"''
  ]
  ++ agenixTokenRun;
  inherit runtimeInputs;
}

{
  wrapPackage,
  callPackage,
  claude-code,
  coreutils,
  git,
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

  ttsBackends = [
    (callPackage ./tts-say.nix { })
    (callPackage ./tts-piper.nix { })
  ];

  speakScript = callPackage ./speak.nix { inherit ttsBackends; };

  runtimeInputs = [
    statuslineScript
    formatFileScript
    rateLimitNotifyScript
    sessionHostScript
    speakScript
    hass-cli-wrapped
    git
    coreutils
  ]
  ++ ttsBackends;

  # Same treatment as GITHUB_TOKEN below: `$(<file)` builtin so the read doesn't
  # need `cat` on the caller's PATH, and a bare assignment so `set -e` aborts on
  # an unreadable secret instead of baking in an empty token.
  agenixTokenRun = lib.optionals readTokenFromAgenix [
    ''ANTHROPIC_AUTH_TOKEN="$(< /run/agenix/z-ai-auth-token)"''
    "export ANTHROPIC_AUTH_TOKEN"
  ];
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

    # Bare assignment, not `export GITHUB_TOKEN=$(…)`: `export VAR=$(cmd)` masks
    # the command's failure under `set -e`, so an unreadable secret would bake in
    # an empty token instead of aborting the launch.
    ''GITHUB_TOKEN="$(cat /run/agenix/github-bot-token)"''
    "export GITHUB_TOKEN"
  ]
  ++ agenixTokenRun;
  inherit runtimeInputs;
}

{
  symlinkJoin,
  makeWrapper,
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
  ttsBackends = [
    (callPackage ./tts-say.nix { })
    (callPackage ./tts-piper.nix { })
  ];
  speakScript = callPackage ./speak.nix { inherit ttsBackends; };
  binPath = lib.makeBinPath (
    [
      statuslineScript
      formatFileScript
      rateLimitNotifyScript
      sessionHostScript
      speakScript
      hass-cli-wrapped
    ]
    ++ ttsBackends
  );
  envFlags = lib.concatStringsSep " " (
    lib.mapAttrsToList (
      name: value: "--set ${lib.escapeShellArg name} ${lib.escapeShellArg value}"
    ) extraEnv
  );
  agenixTokenFlag = lib.optionalString readTokenFromAgenix "--run 'export ANTHROPIC_AUTH_TOKEN=\"$(cat /run/agenix/z-ai-auth-token 2>/dev/null || true)\"'";
in
symlinkJoin {
  name = "claude-code-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ claude-code ];
  meta.mainProgram = binName;
  # Rename before wrapping so a renamed variant ships only e.g. claude-copilot
  # and .claude-copilot-wrapped — no overlap with the base package's claude.
  postBuild = ''
    ${lib.optionalString (binName != "claude") "mv $out/bin/claude $out/bin/${binName}"}
    wrapProgram $out/bin/${binName} \
      --set CLAUDE_CODE_NO_FLICKER 1 \
      --run 'export CLAUDE_CONFIG_DIR="$HOME/setup/pkgs/claude-code-wrapped/config"' \
      --run 'export GITHUB_TOKEN="$(cat /run/agenix/github-bot-token 2>/dev/null || true)"' \
      --set GIT_CONFIG_COUNT 1 \
      --set GIT_CONFIG_KEY_0 include.path \
      --set GIT_CONFIG_VALUE_0 ${./gitconfig-bot} \
      ${agenixTokenFlag} \
      --prefix PATH : ${binPath} \
      ${envFlags}
  '';
}

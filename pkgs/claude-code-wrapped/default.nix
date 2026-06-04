{
  symlinkJoin,
  makeWrapper,
  callPackage,
  claude-code,
  coreutils,
  git,
  jq,
  lib,
  writeShellApplication,
  extraEnv ? { },
  readTokenFromAgenix ? false,
  # Name of the installed binary. Variants override this (e.g. "claude-copilot")
  # so they can be installed alongside the base "claude" without colliding.
  binName ? "claude",
}:
let
  statuslineScript = writeShellApplication {
    name = "claude-plan-usage";
    runtimeInputs = [
      coreutils
      git
      jq
    ];
    inheritPath = false;
    text = builtins.readFile ./claude-plan-usage.sh;
  };
  formatFileScript = callPackage ./format-file.nix { };
  rateLimitNotifyScript = callPackage ./claude-rate-limit-notify.nix { };
  binPath = lib.makeBinPath [
    statuslineScript
    formatFileScript
    rateLimitNotifyScript
  ];
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
      ${agenixTokenFlag} \
      --prefix PATH : ${binPath} \
      ${envFlags}
  '';
}

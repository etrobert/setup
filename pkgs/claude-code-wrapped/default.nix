{
  symlinkJoin,
  makeWrapper,
  claude-code,
  coreutils,
  git,
  jq,
  lib,
  writeShellApplication,
  extraEnv ? { },
  readTokenFromAgenix ? false,
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
  envFlags = lib.concatStringsSep " " (
    lib.mapAttrsToList (name: value: "--set ${lib.escapeShellArg name} ${lib.escapeShellArg value}") extraEnv
  );
  agenixTokenFlag = lib.optionalString readTokenFromAgenix
    "--run 'export ANTHROPIC_AUTH_TOKEN=\"$(cat /run/agenix/z-ai-auth-token 2>/dev/null || true)\"'";
in
symlinkJoin {
  name = "claude-code-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ claude-code ];
  meta.mainProgram = "claude";
  postBuild = ''
    wrapProgram $out/bin/claude \
      --set CLAUDE_CODE_NO_FLICKER 1 \
      --run 'export CLAUDE_CONFIG_DIR="$HOME/setup/pkgs/claude-code-wrapped/config"' \
      --run 'export GITHUB_TOKEN="$(cat /run/agenix/github-bot-token 2>/dev/null || true)"' \
      ${agenixTokenFlag} \
      --prefix PATH : ${statuslineScript}/bin \
      ${envFlags}
  '';
}

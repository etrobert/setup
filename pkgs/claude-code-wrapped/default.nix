{
  symlinkJoin,
  makeWrapper,
  claude-code,
  coreutils,
  git,
  jq,
  writeShellApplication,
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
      --prefix PATH : ${statuslineScript}/bin
  '';
}

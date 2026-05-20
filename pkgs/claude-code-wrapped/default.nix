{
  symlinkJoin,
  makeWrapper,
  claude-code,
  coreutils,
  jq,
  writeShellApplication,
}:
let
  statuslineScript = writeShellApplication {
    name = "claude-plan-usage";
    runtimeInputs = [
      coreutils
      jq
    ];
    inheritPath = false;
    text = ''
      input=$(cat)
      five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
      week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
      out=""
      [ -n "$five" ] && out="5h:$(printf '%.0f' "$five")%"
      [ -n "$week" ] && out="$out 7d:$(printf '%.0f' "$week")%"
      echo "$out"
    '';
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
      --prefix PATH : ${statuslineScript}/bin
  '';
}

{
  symlinkJoin,
  makeWrapper,
  claude-code,
  jq,
  writeShellScript,
  writeText,
}:
let
  statuslineScript = writeShellScript "claude-plan-usage" ''
    input=$(cat)
    five=$(echo "$input" | ${jq}/bin/jq -r '.rate_limits.five_hour.used_percentage // empty')
    week=$(echo "$input" | ${jq}/bin/jq -r '.rate_limits.seven_day.used_percentage // empty')
    out=""
    [ -n "$five" ] && out="5h:$(printf '%.0f' "$five")%"
    [ -n "$week" ] && out="$out 7d:$(printf '%.0f' "$week")%"
    echo "$out"
  '';
  settingsFile = writeText "claude-settings.json" (
    builtins.toJSON {
      statusLine = {
        type = "command";
        command = toString statuslineScript;
      };
    }
  );
in
symlinkJoin {
  name = "claude-code-wrapped";
  nativeBuildInputs = [ makeWrapper ];
  paths = [ claude-code ];
  meta.mainProgram = "claude";
  postBuild = ''
    wrapProgram $out/bin/claude \
      --set CLAUDE_CODE_NO_FLICKER 1 \
      --add-flags "--settings ${settingsFile}"
  '';
}

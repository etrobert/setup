{
  symlinkJoin,
  makeWrapper,
  claude-code,
  jq,
  writeShellApplication,
  writeText,
}:
let
  statuslineScript = writeShellApplication {
    name = "claude-plan-usage";
    runtimeInputs = [ jq ];
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
  settingsFile = writeText "claude-settings.json" (
    builtins.toJSON {
      statusLine = {
        type = "command";
        command = "${statuslineScript}/bin/claude-plan-usage";
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

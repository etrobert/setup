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
      now=$(date +%s)

      fmt_duration() {
        local d=$1
        if [ "$d" -le 0 ]; then
          echo "now"
        elif [ "$d" -lt 3600 ]; then
          echo "$((d / 60))m"
        elif [ "$d" -lt 86400 ]; then
          local h=$((d / 3600)) m=$(( (d % 3600) / 60 ))
          [ "$m" -gt 0 ] && echo "''${h}h''${m}m" || echo "''${h}h"
        else
          local dy=$((d / 86400)) h=$(( (d % 86400) / 3600 ))
          [ "$h" -gt 0 ] && echo "''${dy}d''${h}h" || echo "''${dy}d"
        fi
      }

      five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
      five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
      week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
      week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

      out=""
      if [ -n "$five_pct" ]; then
        five_str="5h:$(printf '%.0f' "$five_pct")%"
        [ -n "$five_reset" ] && five_str="$five_str($(fmt_duration $((five_reset - now))))"
        out="$five_str"
      fi
      if [ -n "$week_pct" ]; then
        week_str="7d:$(printf '%.0f' "$week_pct")%"
        [ -n "$week_reset" ] && week_str="$week_str($(fmt_duration $((week_reset - now))))"
        out="$out $week_str"
      fi
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

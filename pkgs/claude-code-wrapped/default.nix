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
    text = ''
      input=$(cat)
      model=$(echo "$input" | jq -r '.model.display_name')
      cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
      ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
      five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
      five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
      week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
      week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

      branch=$(git branch --show-current 2>/dev/null)

      green=$'\033[32m'
      yellow=$'\033[33m'
      red=$'\033[31m'
      reset=$'\033[0m'

      pct_color() {
        local pct=$1
        if [ "$pct" -ge 80 ]; then
          printf '%s' "$red"
        elif [ "$pct" -ge 50 ]; then
          printf '%s' "$yellow"
        fi
      }

      out="[$model]"
      [ -n "$branch" ] && out="$out $green$branch$reset"
      [ -n "$cost" ] && out="$out | \$$(printf '%.2f' "$cost")"
      if [ -n "$ctx_pct" ]; then
        pct_int=$(printf '%.0f' "$ctx_pct")
        out="$out | $(pct_color "$pct_int")ctx:$pct_int%$reset"
      fi
      if [ -n "$five_pct" ]; then
        pct_int=$(printf '%.0f' "$five_pct")
        five_str="$(pct_color "$pct_int")5h:$pct_int%$reset"
        [ -n "$five_reset" ] && five_str="$five_str ($(date -d "@$five_reset" +"%H:%M"))"
        out="$out | $five_str"
      fi
      if [ -n "$week_pct" ]; then
        pct_int=$(printf '%.0f' "$week_pct")
        week_str="$(pct_color "$pct_int")7d:$pct_int%$reset"
        [ -n "$week_reset" ] && week_str="$week_str ($(date -d "@$week_reset" +"%a %H:%M"))"
        out="$out - $week_str"
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

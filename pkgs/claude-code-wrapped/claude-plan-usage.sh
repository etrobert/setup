input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

branch=$(git branch --show-current 2>/dev/null || true)

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
  if [ -n "$week_reset" ]; then
    week_elapsed_pct=$(week-progress "$week_reset")
    # pace ratio *100: 150 = using 1.5× faster than the week is progressing
    if [ "$week_elapsed_pct" -gt 0 ]; then
      pace=$((pct_int * 100 / week_elapsed_pct))
    else
      pace=0
    fi
    if [ "$pace" -ge 110 ]; then
      week_color="$red"
    elif [ "$pace" -ge 100 ]; then
      week_color="$yellow"
    else
      week_color="$green"
    fi
    pace_display=$(echo "scale=2; $pace / 100" | bc)
    week_str="${week_color}7d:${pct_int}% ×${pace_display}${reset} ($(date -d "@$week_reset" +"%a %H:%M"))"
  else
    week_str="$(pct_color "$pct_int")7d:$pct_int%$reset"
  fi
  out="$out - $week_str"
fi
echo "$out"

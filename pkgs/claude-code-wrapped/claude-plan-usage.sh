input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
# cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
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

# pace_segment LABEL PCT_INT RESET_TS WINDOW_SECONDS DATE_FMT
# Renders a rate-limit segment with pace multiplier when reset_ts is known,
# or plain color-coded percentage when it is not.
pace_segment() {
  local label=$1
  local pct_int=$2
  local reset_ts=$3
  local window_seconds=$4
  local date_fmt=$5
  if [ -n "$reset_ts" ]; then
    local elapsed_pct
    elapsed_pct=$(window-progress "$reset_ts" "$window_seconds")
    local pace
    if [ "$elapsed_pct" -gt 0 ]; then
      pace=$((pct_int * 100 / elapsed_pct))
    else
      pace=0
    fi
    local color
    if [ "$pace" -ge 110 ]; then
      color="$red"
    elif [ "$pace" -ge 100 ]; then
      color="$yellow"
    else
      color="$reset"
    fi
    local pace_display
    pace_display=$(echo "scale=2; $pace / 100" | bc)
    printf '%s' "${color}${label}:${pct_int}% ×${pace_display}${reset} ($(date -d "@$reset_ts" +"$date_fmt"))"
  else
    printf '%s' "$(pct_color "$pct_int")${label}:${pct_int}%${reset}"
  fi
}

out="[$model]"
[ -n "$branch" ] && out="$out $green$branch$reset"
# [ -n "$cost" ] && out="$out | \$$(printf '%.2f' "$cost")"
if [ -n "$ctx_pct" ]; then
  pct_int=$(printf '%.0f' "$ctx_pct")
  out="$out | $(pct_color "$pct_int")ctx:$pct_int%$reset"
fi
if [ -n "$five_pct" ]; then
  pct_int=$(printf '%.0f' "$five_pct")
  out="$out | $(pace_segment "5h" "$pct_int" "$five_reset" "$((5 * 3600))" "%H:%M")"
fi
if [ -n "$week_pct" ]; then
  pct_int=$(printf '%.0f' "$week_pct")
  out="$out - $(pace_segment "7d" "$pct_int" "$week_reset" "$((7 * 24 * 3600))" "%a %H:%M")"
fi
echo "$out"

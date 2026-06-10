input=$(cat)

last_message=$(echo "$input" | jq --raw-output '.last_assistant_message')
reset_time=$(echo "$last_message" | grep --only-matching --perl-regexp '\d+:\d+(?:am|pm)')

if [[ -z "$reset_time" ]]; then
  ntfy publish --quiet --title "Claude" http://tower:2586/home "Could not parse reset time from: ${last_message}"
  exit 1
fi

ntfy publish --quiet --title "Claude" http://tower:2586/home "Usage limit hit — notifying you at ${reset_time}"

# Calculate epoch of reset time
reset_epoch=$(date --date="today $reset_time" +%s)
now_epoch=$(date +%s)

# If the reset time is in the past (e.g. we're past midnight), try tomorrow
if [[ $((reset_epoch - now_epoch)) -le 0 ]]; then
  reset_epoch=$(date --date="tomorrow $reset_time" +%s)
fi

# ntfy minimum scheduled delay is 10s; publish immediately if we're within that
if [[ $((reset_epoch - now_epoch)) -lt 10 ]]; then
  ntfy publish --quiet --title "Claude" http://tower:2586/home "Usage window has reset — you're good to go"
else
  ntfy publish --quiet --title "Claude" --delay "${reset_epoch}" http://tower:2586/home "Usage window has reset — you're good to go"
fi

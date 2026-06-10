input=$(cat)

last_message=$(echo "$input" | jq --raw-output '.last_assistant_message')
reset_time=$(echo "$last_message" | grep --only-matching --perl-regexp '\d+:\d+(?:am|pm)')

if [[ -z "$reset_time" ]]; then
  curl --fail --silent --show-error \
    -H "Title: Claude" \
    -d "Could not parse reset time from: ${last_message}" \
    http://tower:2586/home
  exit 1
fi

curl --fail --silent --show-error \
  -H "Title: Claude" \
  -d "Usage limit hit — notifying you at ${reset_time}" \
  http://tower:2586/home

# Calculate epoch of reset time
reset_epoch=$(date --date="today $reset_time" +%s)
now_epoch=$(date +%s)

# If the reset time is in the past (e.g. we're past midnight), try tomorrow
if [[ $((reset_epoch - now_epoch)) -le 0 ]]; then
  reset_epoch=$(date --date="tomorrow $reset_time" +%s)
fi

# ntfy minimum scheduled delay is 10s; publish immediately if we're within that
if [[ $((reset_epoch - now_epoch)) -lt 10 ]]; then
  curl --fail --silent --show-error \
    -H "Title: Claude" \
    -d "Usage window has reset — you're good to go" \
    http://tower:2586/home
else
  curl --fail --silent --show-error \
    -H "Title: Claude" -H "At: ${reset_epoch}" \
    -d "Usage window has reset — you're good to go" \
    http://tower:2586/home
fi

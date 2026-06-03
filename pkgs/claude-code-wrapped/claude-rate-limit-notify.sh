# notify() and schedule_reset() are injected at build time per platform — see
# claude-rate-limit-notify.nix.

input=$(cat)

last_message=$(echo "$input" | jq --raw-output '.last_assistant_message')
reset_time=$(echo "$last_message" | grep --only-matching --perl-regexp '\d+:\d+(?:am|pm)')

if [[ -z "$reset_time" ]]; then
	notify "Claude (warning)" "Could not parse reset time from: ${last_message}"
	exit 1
fi

# Immediate notification
notify "Claude" "Usage limit hit — notifying you at ${reset_time}"

# Calculate seconds until reset time
reset_epoch=$(date --date="today $reset_time" +%s)
now_epoch=$(date +%s)
delay=$((reset_epoch - now_epoch))

# If the reset time is in the past (e.g. we're past midnight), try tomorrow
if [[ $delay -le 0 ]]; then
	reset_epoch=$(date --date="tomorrow $reset_time" +%s)
	delay=$((reset_epoch - now_epoch))
fi

# Schedule the reset notification
schedule_reset "$delay"

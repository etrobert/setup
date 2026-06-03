input=$(cat)

last_message=$(echo "$input" | jq --raw-output '.last_assistant_message')
reset_time=$(echo "$last_message" | grep --only-matching --perl-regexp '\d+:\d+(?:am|pm)')

if [[ -z "$reset_time" ]]; then
	notify-send "Claude (warning)" "Could not parse reset time from: ${last_message}"
	exit 1
fi

# Immediate notification
notify-send "Claude" "Usage limit hit — notifying you at ${reset_time}"

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
systemd-run --user --on-active="${delay}s" \
	--unit=claude-rate-limit-reset \
	notify-send "Claude" "Usage window has reset — you're good to go"

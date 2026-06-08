# Takes a week_reset unix timestamp as $1.
# Outputs the percentage of the 7-day window elapsed as an integer (0–100).
week_reset=$1
now=$(date +%s)
week_total=$((7 * 24 * 60 * 60))
echo $(((week_total - (week_reset - now)) * 100 / week_total))

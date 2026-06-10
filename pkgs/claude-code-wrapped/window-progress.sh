# Takes a reset unix timestamp as $1 and window length in seconds as $2.
# Outputs the percentage of the window elapsed as an integer (0–100).
reset_ts=$1
window_seconds=$2
now=$(date +%s)
echo $(((window_seconds - (reset_ts - now)) * 100 / window_seconds))

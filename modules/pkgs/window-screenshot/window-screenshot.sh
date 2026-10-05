id=$(niri msg --json pick-window | jq --raw-output '.id // empty')
[[ -n $id ]] || exit 0

raw=$(mktemp --suffix=.png)
out="$HOME/Pictures/Screenshots/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png"

# niri writes the file after the action returns, so wait for its ScreenshotCaptured event
exec {events}< <(niri msg --json event-stream)
events_pid=$!
trap 'kill $events_pid; rm --force "$raw"' EXIT
# The first event means the subscription is live
read -r -u "$events" _

niri msg action screenshot-window --id "$id" --path "$raw"
# shellcheck disable=SC2016 # $path is a jq variable
timeout 5 jq --null-input --exit-status --arg path "$raw" \
  'first(inputs | select(.ScreenshotCaptured.path == $path))' <&"$events" >/dev/null

# Match niri's geometry-corner-radius 12, in physical pixels
scale=$(niri msg --json focused-output | jq '.logical.scale')
radius=$(jq --null-input "12 * $scale | round")
size=$(magick identify -format '%wx%h' "$raw")
width=${size%x*}
height=${size#*x}

# Over must be reset after DstIn, or the shadow merge masks the window away
magick "$raw" \
  \( +clone -alpha transparent -fill white \
  -draw "roundrectangle 0,0 $((width - 1)),$((height - 1)) $radius,$radius" \) \
  -compose DstIn -composite \
  \( +clone -background black -shadow 60x15+0+10 \) +swap \
  -compose Over -background none -layers merge +repage \
  "$out"

wl-copy --type image/png <"$out"

app_id=$1
fnmode=/sys/module/hid_apple/parameters/fnmode

# 2 = F-keys first, 3 = auto (media keys first on Apple keyboards).
set_fnmode() {
  if niri msg --json focused-window |
    jq --exit-status --arg app_id "$app_id" '(.app_id // "") | test($app_id)' >/dev/null; then
    echo 2 >"$fnmode"
  else
    echo 3 >"$fnmode"
  fi
}

set_fnmode
niri msg --json event-stream |
  jq --unbuffered --raw-output 'select(.WindowFocusChanged) | "focus"' |
  while read -r _; do
    set_fnmode
  done

app_id=$1
title=$2

declare -A floated

niri msg --json event-stream |
  jq --unbuffered --raw-output --arg app_id "$app_id" --arg title "$title" '
    .WindowOpenedOrChanged.window
    | select(.is_floating == false and (.app_id | test($app_id)) and (.title | test($title)))
    | .id
  ' |
  while read -r id; do
    # Float each window only once, so manually tiling it again (Mod+V) sticks.
    [[ -n ${floated[$id]:-} ]] && continue
    floated[$id]=1
    niri msg action move-window-to-floating --id "$id"
  done

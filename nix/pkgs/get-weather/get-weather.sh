#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Source https://github.com/Alexays/Waybar/wiki/Module:-Custom:-Examples#weather
# See https://github.com/chubin/wttr.in

# Location based on IP address
if ! text=$(curl -s "https://wttr.in?format=%t"); then
  # Do not display anything if there's an error
  jq --null-input --compact-output '{text: ""}'
  exit
fi

# Remove prefix +
text="${text#+}"
# Remove suffix C
text="${text%C}"

jq --null-input --compact-output --arg text "$text" '{text: $text}'

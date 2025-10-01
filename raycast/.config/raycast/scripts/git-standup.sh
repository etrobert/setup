#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Standup
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 💻

# Documentation:
# @raycast.author Étienne Robert
# @raycast.authorURL https://github.com/etrobert
# @raycast.description Lists your commits from the last 24 hours.

cd "/Users/etienne/work/banani-web-main" || exit 1

# On Monday, show commits since Friday; otherwise since yesterday
if [ "$(date +%u)" -eq 1 ]; then
  SINCE="last friday"
else
  SINCE="yesterday.midnight"
fi

git log \
  --all \
  --author="$(git config user.name)" \
  --since="$SINCE" \
  --pretty=format:"%C(yellow)%d%Creset %s %Cblue(%ar)%Creset"

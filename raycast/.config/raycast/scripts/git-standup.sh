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

cd "/Users/etienne/work/haii" || exit 1

git log \
  --all \
  --author="$(git config user.name)" \
  --since=yesterday.midnight \
  --pretty=format:"%C(yellow)%d%Creset %s %Cblue(%ar)%Creset"

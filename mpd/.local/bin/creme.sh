#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

song=$(mpc current --format "%file%")
if [[ -z "$song" ]]; then
  echo "Nothing is currently playing"
  exit 1
fi
echo "$song" >>~/sync/playlists/creme.m3u
echo "Added: $song"

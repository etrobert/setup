#!/usr/bin/env bash
# Drive an implementation of save-displays through dock, undock and hotdesk
# against a mock niri, and check that an unplugged screen keeps its position.
#
#   test/scenario.sh 'nix run .#save-displays-rs --'

set -o errexit -o nounset -o pipefail

implementation=${1:?usage: scenario.sh <command that runs save-displays>}
here=$(dirname "$(readlink --canonicalize "$0")")

# AF_UNIX paths are capped near 100 bytes, so stay out of deep temp dirs.
socket=${XDG_RUNTIME_DIR:?}/save-displays-test.sock
home=$(mktemp --directory)
fixture=$home/outputs.json
trap 'rm --recursive --force "$home" "$socket"; kill %1 2>/dev/null' EXIT

docked() { cat "$here/fixtures/docked.json"; }
docked >"$fixture"
python3 "$here/mock-niri.py" "$fixture" "$socket" >/dev/null &
until [ -S "$socket" ]; do sleep 0.1; done

save() { HOME=$home NIRI_SOCKET=$socket $implementation; }

save
jq '{"eDP-1": .["eDP-1"]}' <(docked) >"$fixture" # undocked
save
jq '{"eDP-1": .["eDP-1"], "DP-2": (.["DP-1"] | .make = "Acme" | .model = "XYZ" | .serial = "123" | .name = "DP-2")}' \
  <(docked) >"$fixture" # a hotdesk screen
save

saved=$home/.local/state/niri/outputs.json
niri validate --config "$home/.local/state/niri/outputs.kdl"

for screen in "LG Display 0x05EE Unknown" \
  "Philips Consumer Electronics Company PHL 329P1 AU82510000017" \
  "Acme XYZ 123"; do
  jq --exit-status --arg screen "$screen" 'has($screen)' "$saved" >/dev/null ||
    {
      echo "lost $screen"
      exit 1
    }
done

jq --exit-status '.["Philips Consumer Electronics Company PHL 329P1 AU82510000017"]
  | .x == 93 and .y == 0' "$saved" >/dev/null ||
  {
    echo "the unplugged Philips moved"
    exit 1
  }

echo "ok: three screens remembered, the unplugged one kept its position"

#!/usr/bin/env bash
# Run once on tower from the repo root, then delete this script and the .age files it reads.
set -euo pipefail

age=$(nix build --no-link --print-out-paths nixpkgs#age)/bin/age

# field(re): the named group v of re, failing loudly when the plaintext does not match.
lib='def field(re): (capture(re) // error("no match")).v;'

put() { # name [jq filter]
  sudo "$age" --decrypt --identity /etc/ssh/ssh_host_ed25519_key "secrets/$1.age" |
    jq --raw-input --slurp --arg name "$1" "$lib ${2:-{(\$name): .\}}"
}

{
  put harmonia-signing-key
  put c411-api-key
  put dispatch-claude-token '{"dispatch-claude-token": field("^CLAUDE_CODE_OAUTH_TOKEN=(?<v>[^\\n]+)\\n?$")}'
  put dispatch-github-token '{"dispatch-github-token": field("^GH_TOKEN=(?<v>[^\\n]+)\\n?$")}'
} | jq --slurp add |
  nix run nixpkgs#sops -- encrypt --input-type json --output-type yaml --filename-override secrets/tower.yaml >secrets/tower.yaml

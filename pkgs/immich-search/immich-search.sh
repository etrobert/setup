#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Immich's own CLI only uploads (login/logout/server-info/upload), so searching
# goes straight at the REST API. See https://immich.app/docs/api
#
# `ocr` and `smart` mirror Immich's own vocabulary: the web UI's search-type
# selector calls them OCR and Context.

: "${IMMICH_URL:=http://tower:2283}"

size=10

# Deferred so --help works without the secret, and a bare assignment rather than
# `: "${IMMICH_API_KEY:=$(<file)}"` so `set -o errexit` aborts on an unreadable
# key instead of silently authenticating with an empty one.
read_api_key() {
  if [[ -z ${IMMICH_API_KEY:-} ]]; then
    IMMICH_API_KEY=$(</run/agenix/immich-api-key)
  fi
}

usage() {
  cat >&2 <<'EOF'
Usage:
  immich-search ocr <query>    Photos whose recognized text matches (wifi passwords, signs, notes)
  immich-search smart <query>  Photos by what they depict, via CLIP ("elephant", "sunset at the beach")
  immich-search read <id>      Print every scrap of recognized text in one photo

Options:
  --size <n>  Maximum results (default 10)

Text matching is fuzzy and accent-insensitive, so search single words rather
than exact phrases.
EOF
  exit 1
}

api() {
  local method=$1 path=$2
  shift 2
  curl --silent --show-error --fail \
    --request "$method" \
    --header "x-api-key: $IMMICH_API_KEY" \
    --header 'Content-Type: application/json' \
    "$IMMICH_URL/api$path" "$@"
}

# One line per asset: date, place, filename, and a link that opens it in Immich.
summarize() {
  jq --raw-output --arg url "$IMMICH_URL" '
    .assets.items[]
    | [
        .id,
        ((.exifInfo.dateTimeOriginal // .fileCreatedAt // "?")[0:10]),
        ([.exifInfo.city, .exifInfo.state, .exifInfo.country]
          | map(select(. != null and . != ""))
          # Berlin is both city and state; collapse such repeats.
          | reduce .[] as $part ([]; if .[-1] == $part then . else . + [$part] end)
          | join(", ")
          | if . == "" then "no location" else . end),
        .originalFileName,
        "\($url)/photos/\(.id)"
      ]
    | @tsv'
}

recognized_text() {
  local id=$1 prefix=${2:-}
  api GET "/assets/$id/ocr" |
    jq --raw-output --arg prefix "$prefix" '.[] | select(.text != "") | $prefix + .text'
}

search() {
  local endpoint=$1 body=$2 with_text=$3
  local response id date place name link

  response=$(api POST "/search/$endpoint" --data "$body")

  if [[ $(jq '.assets.items | length' <<<"$response") -eq 0 ]]; then
    echo "No matches." >&2
    return 1
  fi

  while IFS=$'\t' read -r id date place name link; do
    printf '%s  %s\n  %s  %s\n' "$date" "$place" "$name" "$link"
    if [[ $with_text == yes ]]; then
      recognized_text "$id" '    | '
    fi
    echo
  done < <(summarize <<<"$response")
}

[[ $# -ge 1 ]] || usage
command=$1
shift

args=()
while [[ $# -gt 0 ]]; do
  case $1 in
  --size)
    [[ $# -ge 2 ]] || usage
    size=$2
    shift 2
    ;;
  --help | -h) usage ;;
  *)
    args+=("$1")
    shift
    ;;
  esac
done

[[ ${#args[@]} -eq 1 ]] || usage
query=${args[0]}

read_api_key

case $command in
ocr)
  search metadata \
    "$(jq --null-input --arg q "$query" --argjson n "$size" \
      '{ocr: $q, size: $n, withExif: true}')" \
    yes
  ;;
smart)
  search smart \
    "$(jq --null-input --arg q "$query" --argjson n "$size" \
      '{query: $q, size: $n, withExif: true}')" \
    no
  ;;
read) recognized_text "$query" ;;
*) usage ;;
esac

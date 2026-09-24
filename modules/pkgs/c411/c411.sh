[[ $# -gt 0 ]] || { echo "Usage: c411 <search terms>" >&2; exit 1; }

feed=$(curl --silent --show-error --fail --get \
  --data-urlencode "apikey=$(< /run/agenix/c411-api-key)" \
  --data-urlencode "t=music" \
  --data-urlencode "q=$*" \
  https://c411.org/api/torznab)

# shellcheck disable=SC2016  # $-names are XQuery variables, not shell
choice=$(xidel - --silent --xquery '
  for $item at $n in //item
  return string-join(
    ($n, $item/*:attr[@name="seeders"]/@value || " seeds",
     format-number($item/size div 1000000000, "0.00") || "G", $item/title), "  ")
' <<< "$feed" | fzf --with-nth=2.. --height=40% --reverse)

link=$(xidel - --silent --xpath "(//item)[${choice%% *}]/enclosure/@url" <<< "$feed")
transmission-remote torrents:80 --add "$link"

config=/tank/kleinanzeigen/watches.json
seen=$STATE_DIRECTORY/seen

# The app API namespaces its JSON keys, so filters index by variable rather
# than repeating this.
ads_key='{http://www.ebayclassifiedsgroup.com/schema/ad/v1}ads'

# Berlin, per locations/top-locations.json?q=Berlin. A coarse server-side
# filter only; maxKm is measured from the configured origins.
berlin_location_id=3331
berlin_radius_km=15

if ! jq --exit-status '
  (.origins | type == "array" and length > 0
    and all(.[]; (.name | type == "string")
      and (.lat | type == "number") and (.lon | type == "number")))
  and (.watches | type == "array" and length > 0
    and all(.[]; (.query | type == "string")
      and (.maxPrice | type == "number") and (.maxKm | type == "number")))
' "$config" >/dev/null; then
  echo "$config is missing or malformed" >&2
  exit 1
fi

origins=$(jq --compact-output '.origins' "$config")

# A first run would otherwise fire one notification per existing match; seed
# the state file silently instead.
seeding=""
if [ ! -e "$seen" ]; then
  seeding=1
  touch "$seen"
  echo "first run: recording current matches without notifying"
fi

failed=0
total=0

while IFS=$'\t' read -r query maxPrice maxKm; do
  if ! response=$(curl --silent --fail --show-error --get \
    --header 'Authorization: Basic YW5kcm9pZDpUYVI2MHBFdHRZ' \
    --header 'User-Agent: okhttp/4.10.0' \
    --header 'Accept: application/json' \
    --data-urlencode "q=$query" \
    --data 'size=41&sortType=DATE_DESCENDING&includeTopAds=false' \
    --data "locationId=$berlin_location_id&distance=$berlin_radius_km" \
    https://api.kleinanzeigen.de/api/ads.json); then
    echo "$query: fetch failed" >&2
    failed=1
    continue
  fi

  # 41 newest Berlin ads per query, no paging: at a 15-minute poll a query
  # would have to gain 41 ads in 15 minutes to lose one.
  ads=$(jq --arg k "$ads_key" '.[$k].value.ad // [] | length' <<<"$response")
  total=$((total + ads))

  matches=$(jq --raw-output \
    --arg k "$ads_key" \
    --argjson origins "$origins" \
    --argjson maxPrice "$maxPrice" \
    --argjson maxKm "$maxKm" '
      def unesc: gsub("&#x2F;"; "/") | gsub("&quot;"; "\"")
        | gsub("&#39;"; "\u0027") | gsub("&amp;"; "&");

      def rad: . * 3.141592653589793 / 180;

      def km($alat; $alon; $blat; $blon):
        ((($blat - $alat) | rad / 2 | sin) as $s1
         | (($blon - $alon) | rad / 2 | sin) as $s2
         | ($s1 * $s1 + ($alat | rad | cos) * ($blat | rad | cos) * $s2 * $s2) as $a
         | 12742 * atan2($a | sqrt; (1 - $a) | sqrt));

      .[$k].value.ad // []
      | .[]
      | select(."ad-address".latitude.value and ."ad-address".longitude.value)
      | (."ad-address".latitude.value | tonumber) as $lat
      | (."ad-address".longitude.value | tonumber) as $lon
      # Price-on-request is dealer noise; "zu verschenken" is a real 0 EUR and
      # should pass any cap.
      | select(.price."price-type".value | . == "SPECIFIED_AMOUNT" or . == "FREE")
      | (.price.amount.value // 0) as $price
      | ($origins | map({ name, d: km(.lat; .lon; $lat; $lon) }) | min_by(.d)) as $near
      | select($price <= $maxPrice and $near.d <= $maxKm)
      | [.id, (.title.value | unesc), $price, ($near.d * 10 | round / 10), $near.name,
         first(.link[] | select(.rel == "self-public-website") | .href),
         # teaser is ~4 KB; large and XXL are wasteful for a notification.
         (first(.pictures.picture[]?.link[] | select(.rel == "teaser") | .href) // "")]
      | @tsv
    ' <<<"$response")

  matched=0
  [ -n "$matches" ] && matched=$(grep --count '' <<<"$matches")
  new=0

  while IFS=$'\t' read -r id title price dist where url img; do
    [ -n "$id" ] || continue
    grep --quiet --fixed-strings --line-regexp "$id" "$seen" && continue
    new=$((new + 1))

    if [ -n "$seeding" ]; then
      echo "$id" >>"$seen"
      continue
    fi

    echo "$query: new $id - $title ($price EUR, $dist km from $where)"

    # The ntfy clients only preview attachments the server itself hosts; a
    # remote --attach URL renders as a filename. So fetch the photo and
    # upload it. A failed fetch must not cost us the notification.
    photo=""
    attach=()
    if [ -n "$img" ]; then
      photo=$(mktemp --tmpdir kleinanzeigen-XXXXXXXX.jpg)
      if curl --silent --fail --max-time 15 --output "$photo" "$img"; then
        attach=(--file "$photo")
      else
        echo "$query: photo fetch failed for $id" >&2
      fi
    fi

    if printf '%s EUR - %s km from %s\n' "$price" "$dist" "$where" |
      ntfy publish --quiet --title "$title" \
        --actions "view, Open listing, $url" "${attach[@]}"; then
      echo "$id" >>"$seen"
    else
      echo "$query: notification failed for $id" >&2
      failed=1
    fi

    [ -n "$photo" ] && rm --force "$photo"
  done <<<"$matches"

  echo "$query: $ads ads, $matched matching, $new new"
done < <(jq --raw-output '.watches[] | [.query, .maxPrice, .maxKm] | @tsv' "$config")

# Every query coming back empty means the API changed or the app token
# rotated, not that Berlin ran out of listings.
if [ "$total" -eq 0 ]; then
  echo "no ads returned by any query - API or token likely broken" >&2
  exit 1
fi

exit "$failed"

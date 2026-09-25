availabilities='https://eu.api.ovh.com/1.0/dedicated/server/datacenter/availabilities'
catalog='https://eu.api.ovh.com/1.0/order/catalog/public/eco?ovhSubsidiary=DE'
state=$STATE_DIRECTORY/available
current=$STATE_DIRECTORY/current

# Nothing in this API names the range, but every Kimsufi plan code looks like
# 24sk40-v1.
plans='^[0-9]+sk'

# Below 4 TB there is nothing worth moving the library onto.
min_disk_gb=4000

# Berlin latency rules out bhs, sgp and syd.
datacenters='["fra","gra","lon","rbx","sbg","waw"]'

# "unknown" is a placeholder rather than a stock level, and sits for months on
# plans that never restock. comingSoon is not orderable either.
unorderable='["unavailable","comingSoon","unknown"]'

# --compressed: 137 KB against 4.2 MB plain.
if ! response=$(curl --silent --fail --show-error --compressed "$availabilities"); then
  echo "availability fetch failed" >&2
  exit 1
fi

# No Kimsufi rows at all means the plan-code shape changed, not that OVH
# retired the range overnight.
if [ "$(jq --arg plans "$plans" \
  '[.[] | select(.planCode | test($plans))] | length' <<<"$response")" -eq 0 ]; then
  echo "no Kimsufi plans in the availability feed - API shape likely changed" >&2
  exit 1
fi

jq --raw-output \
  --arg plans "$plans" \
  --argjson min "$min_disk_gb" \
  --argjson datacenters "$datacenters" \
  --argjson unorderable "$unorderable" '
    .[]
    | select(.planCode | test($plans))
    # storage reads like softraid-2x4000sa or softraid-2x960nvme-2x6000sa.
    | select([.storage | scan("x([0-9]+)sa")] | flatten | map(tonumber) | max >= $min)
    | .planCode as $plan
    | .storage as $storage
    # One row per full spec, so --unique below folds the RAM variants of the
    # same orderable config back into one line.
    | .datacenters[]
    | select(.datacenter | IN($datacenters[]))
    | select(.availability | IN($unorderable[]) | not)
    | [$plan, $storage, .datacenter, .availability]
    | @tsv
  ' <<<"$response" | sort --unique >"$current"

# Stock oscillates, so the state is what was orderable last run rather than a
# log of everything ever seen: a config that sells out and returns has to
# notify again.
if [ ! -e "$state" ]; then
  echo "first run: recording current availability without notifying"
  mv "$current" "$state"
  exit 0
fi

new=$(comm -13 "$state" "$current")

if [ -z "$new" ]; then
  echo "$(wc --lines <"$current") orderable, nothing new"
  mv "$current" "$state"
  exit 0
fi

# 460 KB against the availability feed's 137 KB, and only the wording of the
# notification needs it, so fetch it only when there is something to announce.
if ! catalog_response=$(curl --silent --fail --show-error --compressed "$catalog"); then
  echo "catalog fetch failed" >&2
  exit 1
fi

# invoiceName reads "KS-4 | Intel Xeon-E3 1230 v6", and the part before the
# pipe is what the website calls the model.
names=$(jq --compact-output \
  '[.plans[] | { key: .planCode, value: (.invoiceName | split(" |")[0]) }] | from_entries' \
  <<<"$catalog_response")

failed=0

while IFS=$'\t' read -r plan storage datacenter availability; do
  name=$(jq --raw-output --arg plan "$plan" '.[$plan] // $plan' <<<"$names")
  echo "orderable: $name ($plan) $storage in $datacenter - $availability"

  if ! printf '%s - %s\n' "$storage" "$availability" |
    ntfy publish --quiet --title "$name orderable in $datacenter" \
      --actions "view, Order, https://eco.ovhcloud.com/de/kimsufi/"; then
    echo "notification failed for $plan in $datacenter" >&2
    failed=1
  fi
done <<<"$new"

# Leaving the state untouched re-sends the whole batch next run, which beats
# silently dropping a restock we failed to announce.
[ "$failed" -eq 0 ] || exit 1

mv "$current" "$state"

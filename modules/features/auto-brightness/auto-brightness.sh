day=$1
night=$2

# Berlin, as in darkman.nix; day above 6°, night below -6° (end of civil twilight)
brightness=$(heliocron --latitude 52.5 --longitude 13.4 poll --json | jq --arg day "$day" --arg night "$night" '
  ($day | tonumber) as $day | ($night | tonumber) as $night
  | ([[(6 - .solar_elevation) / 12, 0] | max, 1] | min) as $fade
  | $day - ($day - $night) * $fade | round')

noctalia msg brightness-set all "$brightness%"

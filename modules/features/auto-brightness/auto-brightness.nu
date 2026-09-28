def main [day: int, night: int] {
  # Berlin, as in darkman.nix
  let sun = heliocron --latitude 52.5 --longitude 13.4 poll --json | from json | get solar_elevation

  # Day above 6°, night below -6° (end of civil twilight)
  let fade = [([((6 - $sun) / 12) 0] | math max) 1] | math min

  let brightness = $day - ($day - $night) * $fade | math round
  noctalia msg brightness-set all $"($brightness)%"
}

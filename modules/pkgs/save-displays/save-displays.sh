state=$HOME/.local/state/niri
store=$state/outputs.json
layout=$state/outputs.kdl

mkdir --parents "$state"

# Screens that are unplugged keep their entry: that is the whole point, and a
# wlr-output-management apply drops them from niri's own copy (niri#676).
niri msg --json outputs | jq --argjson saved "$(cat "$store" 2>/dev/null || echo '{}')" '
  def identity:
    if .make == "Unknown" and .model == "Unknown" and .serial == null
    then .name
    else "\(.make) \(.model) \(.serial // "Unknown")"
    end;

  $saved + ([
    # An interlaced mode leaves a screen that is on with no mode to name.
    .[] | select(.logical and .current_mode != null) | {
      key: identity,
      value: {
        mode: (.modes[.current_mode] | "\(.width)x\(.height)@\(.refresh_rate / 1000)"),
        scale: .logical.scale,
        transform: (.logical.transform | ascii_downcase | sub("^flipped(?<d>\\d)"; "flipped-\(.d)")),
        x: .logical.x,
        y: .logical.y,
      },
    }
  ] | from_entries)
' >"$store.new"
mv "$store.new" "$store"

# @json quotes the name: an unescaped quote in an EDID string would take the
# whole niri config down with it, not just this file.
jq --raw-output '
  to_entries | .[] |
  "output \(.key | @json) {\n    mode \"\(.value.mode)\"\n    scale \(.value.scale)\n    transform \"\(.value.transform)\"\n    position x=\(.value.x) y=\(.value.y)\n}"
' "$store" >"$layout.new"
# niri polls this file every 500ms, so swap it in one step rather than letting
# it read a half-written config.
mv "$layout.new" "$layout"

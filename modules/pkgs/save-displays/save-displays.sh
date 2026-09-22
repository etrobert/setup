state=${XDG_STATE_HOME:-$HOME/.local/state}/niri
store=$state/outputs.json
layout=$state/outputs.kdl

mkdir --parents "$state"
[ -e "$store" ] || echo '{}' >"$store"

# Screens that are unplugged keep their entry: that is the whole point, and a
# wlr-output-management apply drops them from niri's own copy (niri#676).
niri msg --json outputs | jq --slurpfile saved "$store" '
  def identity:
    if .make == "Unknown" and .model == "Unknown" and .serial == null
    then .name
    else "\(.make) \(.model) \(.serial // "Unknown")"
    end;

  # Measure from the built-in panel, so dragging it in the GUI moves the
  # screens next to it today rather than the ones saved for another desk.
  (first(.[] | select(.logical and (.name | test("^(eDP|LVDS|DSI)"))) | .logical)
    // { x: 0, y: 0 }) as $origin

  | $saved[0] + ([
    .[] | select(.logical) | {
      key: identity,
      value: {
        mode: (.modes[.current_mode] | "\(.width)x\(.height)@\(.refresh_rate / 1000)"),
        scale: .logical.scale,
        transform: (.logical.transform | ascii_downcase | sub("^flipped(?<d>\\d)"; "flipped-\(.d)")),
        x: (.logical.x - $origin.x),
        y: (.logical.y - $origin.y),
      },
    }
  ] | from_entries)
' >"$store.new"
mv "$store.new" "$store"

jq --raw-output '
  to_entries | .[] |
  "output \"\(.key)\" {\n    mode \"\(.value.mode)\"\n    scale \(.value.scale)\n    transform \"\(.value.transform)\"\n    position x=\(.value.x) y=\(.value.y)\n}"
' "$store" >"$layout.new"
# niri polls this file every 500ms, so swap it in one step rather than letting
# it read a half-written config.
mv "$layout.new" "$layout"

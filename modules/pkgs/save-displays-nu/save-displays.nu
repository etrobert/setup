let state = $"($env.HOME)/.local/state/niri"
let store = $"($state)/outputs.json"
let layout = $"($state)/outputs.kdl"

mkdir $state

# Screens that are unplugged keep their entry: that is the whole point, and a
# wlr-output-management apply drops them from niri's own copy (niri#676).
let saved = if ($store | path exists) { open --raw $store | from json } else { {} }

let connected = niri msg --json outputs | from json | values
  # An interlaced mode leaves a screen that is on with no mode to name.
  | where logical != null and current_mode != null
  | reduce --fold {} {|out, acc|
      let id = if $out.make == "Unknown" and $out.model == "Unknown" and $out.serial == null {
        $out.name
      } else {
        $"($out.make) ($out.model) ($out.serial | default "Unknown")"
      }
      let mode = $out.modes | get $out.current_mode
      $acc | insert $id {
        mode: $"($mode.width)x($mode.height)@($mode.refresh_rate / 1000)"
        scale: $out.logical.scale
        transform: ($out.logical.transform | str lowercase | str replace --regex '^flipped(\d)' 'flipped-$1')
        x: $out.logical.x
        y: $out.logical.y
      }
    }

let merged = $saved | merge $connected

$merged | to json | save --force $"($store).new"
mv $"($store).new" $store

# to json quotes the name: an unescaped quote in an EDID string would take the
# whole niri config down with it, not just this file.
$merged
  | items {|id, screen| [
      $"output ($id | to json) {"
      $"    mode ($screen.mode | to json)"
      $"    scale ($screen.scale)"
      $"    transform ($screen.transform | to json)"
      $"    position x=($screen.x) y=($screen.y)"
      "}"
    ] | str join "\n" }
  | append ""
  | str join "\n"
  | save --force $"($layout).new"
# niri polls this file every 500ms, so swap it in one step rather than letting
# it read a half-written config.
mv $"($layout).new" $layout

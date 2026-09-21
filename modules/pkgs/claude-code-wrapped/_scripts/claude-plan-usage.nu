# writeNuBin's shebang cannot pass --stdin, so $in is empty; read it by path.
let input = open --raw /dev/stdin | from json

def pct-color [pct: int]: nothing -> string {
    match $pct {
        $p if $p >= 80 => (ansi red)
        $p if $p >= 50 => (ansi yellow)
        _ => ""
    }
}

# With a reset time, shows how far ahead of an even burn the window is; the
# colour then tracks that pace instead of the percentage.
def limit-segment [
    label: string
    pct: int
    reset_ts
    window: duration
    date_fmt: string
]: nothing -> string {
    if $reset_ts == null {
        return $"(pct-color $pct)($label):($pct)%(ansi reset)"
    }
    let reset = $reset_ts | into datetime --timezone local --format "%s"
    let elapsed_pct = ($window - ($reset - (date now))) / $window * 100
    let pace = if $elapsed_pct > 0 { $pct / $elapsed_pct } else { 0 }
    let color = match $pace {
        $p if $p >= 1.1 => (ansi red)
        $p if $p >= 0.9 => (ansi yellow)
        _ => ""
    }
    let pace_display = $pace | into string --decimals 2
    let reset_display = $reset | format date $date_fmt
    $"($color)($label):($pct)% ×($pace_display)(ansi reset) \(($reset_display))"
}

let model = $"[($input.model.display_name)]"
let branch = git branch --show-current | complete | get stdout | str trim

let branch = if ($branch | is-not-empty) {
    $"(ansi green)($branch)(ansi reset)"
}

let ctx_pct = $input | get -o context_window.used_percentage

let ctx = if ($ctx_pct | is-not-empty) {
    let pct = $ctx_pct | math round | into int
    $"(pct-color $pct)ctx:($pct)%(ansi reset)"
}

let five_hour_pct = $input | get -o rate_limits.five_hour.used_percentage

let five_hour = if ($five_hour_pct | is-not-empty) {
    let reset_ts = $input | get -o rate_limits.five_hour.resets_at
    (limit-segment
        "5h"
        ($five_hour_pct | math round | into int)
        $reset_ts
        5hr
        "%H:%M"
    )
}

let seven_day_pct = $input | get -o rate_limits.seven_day.used_percentage

let seven_day = if ($seven_day_pct | is-not-empty) {
    let reset_ts = $input | get -o rate_limits.seven_day.resets_at
    (limit-segment
        "7d"
        ($seven_day_pct | math round | into int)
        $reset_ts
        7day
        "%a %H:%M"
    )
}

# Sections are separated by |; the two limits within their section by -.
let limits = [$five_hour $seven_day] | compact | str join " - "

let sections = [
    ([$model $branch] | compact | str join " ")
    $ctx
    $limits
]
# As an argument: `str join` yields a stream, which print would pass through
# without the line ending.
print ($sections | compact --empty | str join " | ")

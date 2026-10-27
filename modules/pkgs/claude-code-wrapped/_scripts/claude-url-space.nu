# Ghostty's Ctrl+Click includes a trailing . , : ? or ) in the link
def main [] {
    # cat: Claude Code's hook stdin is a socket, which open cannot read
    let delta = cat | from json | get delta
    let url = r#'(?<url>https?://[^\s<>"'`]*[^\s<>"'`.,:?)]>?)'#
    let tail = r#'(?<tail>[.,:?)]+)(?<end>[\s<>"'`]|$)'#
    {
        hookSpecificOutput: {
            hookEventName: "MessageDisplay"
            displayContent: ($delta | str replace --all --regex $"($url)($tail)" '$url $tail$end')
        }
    } | to json
}

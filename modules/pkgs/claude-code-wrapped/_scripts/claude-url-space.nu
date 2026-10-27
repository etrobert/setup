# Ghostty's Ctrl+Click includes a trailing . , : ? or ) in the link
# cat: Claude Code's hook stdin is a socket, which open cannot read
let delta = cat | from json | get delta
{
    hookSpecificOutput: {
        hookEventName: "MessageDisplay"
        displayContent: (
            $delta
            | str replace --all --regex '(?<url>https?://\S+?)(?<tail>[.,:?)]+)(?<end>\s|$)' '$url $tail$end'
        )
    }
} | to json

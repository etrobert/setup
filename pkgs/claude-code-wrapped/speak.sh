# Speak the current Claude Code session's last assistant message aloud.
# Reads the message straight from the session transcript, so it runs instantly
# and costs no model tokens. Invoke in-session with the bash prefix: `!speak`.
# Markdown formatting is stripped so the spoken output is plain prose.
#
# The text is piped to a swappable TTS backend named by $SPEAK_TTS (default
# tts-piper). Set e.g. SPEAK_TTS=tts-say to switch engines without a rebuild;
# each backend reads text on stdin and speaks it.

config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Transcripts are named <session-id>.jsonl under projects/<encoded-cwd>/. Outside
# a Claude session CLAUDE_CODE_SESSION_ID is unset, so nounset aborts here.
transcript=$(find "$config/projects" -type f -name "$CLAUDE_CODE_SESSION_ID.jsonl" 2>/dev/null | head --lines=1)
if [ -z "$transcript" ]; then
  echo "speak: transcript for session $CLAUDE_CODE_SESSION_ID not found under $config/projects" >&2
  exit 1
fi

# Last assistant entry that actually has text (skip trailing tool-only entries),
# joining its text blocks. Markdown is stripped so the TTS backend reads prose
# rather than literal "asterisk asterisk", backticks, hash headers, and link URLs.
text=$(
  jq --raw-output --slurp '
    # Reduce common Markdown to its spoken text, rule by rule. Underscore
    # emphasis is deliberately left alone to avoid mangling snake_case
    # identifiers and file_paths.
    def strip_md:
      # Drop fenced-code delimiter lines (``` optionally followed by a language),
      # leaving the code body to be spoken as plain text.
      gsub("(?m)^```.*$"; "")
      # Unwrap `inline code`, keeping the captured contents.
      | gsub("`(?<c>[^`]*)`"; .c)
      # Image ![alt](url) -> just the alt text.
      | gsub("!\\[(?<t>[^\\]]*)\\]\\([^)]*\\)"; .t)
      # Link [text](url) -> just the link text, discarding the URL.
      | gsub("\\[(?<t>[^\\]]*)\\]\\([^)]*\\)"; .t)
      # **bold** -> bold. Must run before the single-asterisk rule below.
      | gsub("\\*\\*(?<t>[^*]+)\\*\\*"; .t)
      # *italic* -> italic.
      | gsub("\\*(?<t>[^*]+)\\*"; .t)
      # ~~strikethrough~~ -> strikethrough.
      | gsub("~~(?<t>[^~]+)~~"; .t)
      # Strip leading ATX heading markers (# .. ######) and their trailing space.
      | gsub("(?m)^\\s{0,3}#{1,6}\\s+"; "")
      # Strip the leading > of blockquote lines.
      | gsub("(?m)^\\s{0,3}>\\s?"; "")
      # Strip unordered list markers (-, *, +) at the start of a line.
      | gsub("(?m)^\\s*[-*+]\\s+"; "")
      # Strip ordered list markers (1., 2., ...) at the start of a line.
      | gsub("(?m)^\\s*\\d+\\.\\s+"; "")
      ;
    [ .[]
      | select(.type == "assistant")
      | (.message.content // [])
      | map(select(.type == "text") | .text)
      | join("\n")
      | select(. != "")
    ] | (last // "") | strip_md
  ' "$transcript"
)

if [ -z "$text" ]; then
  echo "speak: no assistant text to speak" >&2
  exit 1
fi

printf '%s' "$text" | "${SPEAK_TTS:-tts-piper}"

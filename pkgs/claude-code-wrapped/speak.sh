# Speak the current Claude Code session's last assistant message aloud, verbatim.
# Reads the message straight from the session transcript, so it runs instantly
# and costs no model tokens. Invoke in-session with the bash prefix: `!speak`.
#
# The text is piped to the `tts` backend, whose engine is chosen at build time
# in default.nix (swap the tts-*.nix wired there and rebuild to change engine).

config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Transcripts are named <session-id>.jsonl under projects/<encoded-cwd>/. Outside
# a Claude session CLAUDE_CODE_SESSION_ID is unset, so nounset aborts here.
transcript=$(find "$config/projects" -type f -name "$CLAUDE_CODE_SESSION_ID.jsonl" 2>/dev/null | head --lines=1)
if [ -z "$transcript" ]; then
  echo "speak: transcript for session $CLAUDE_CODE_SESSION_ID not found under $config/projects" >&2
  exit 1
fi

# Last assistant entry that actually has text (skip trailing tool-only entries),
# joining its text blocks.
text=$(
  jq --raw-output --slurp '
    [ .[]
      | select(.type == "assistant")
      | (.message.content // [])
      | map(select(.type == "text") | .text)
      | join("\n")
      | select(. != "")
    ] | last // ""
  ' "$transcript"
)

if [ -z "$text" ]; then
  echo "speak: no assistant text to speak" >&2
  exit 1
fi

printf '%s' "$text" | tts

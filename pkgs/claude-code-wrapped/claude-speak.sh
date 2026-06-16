#!/usr/bin/env bash
# Stop hook: read the final assistant message aloud via TTS.
# Set CLAUDE_SPEAK=0 to mute without rebuilding.

set -euo pipefail

if [[ "${CLAUDE_SPEAK:-}" == "0" ]]; then
  exit 0
fi

input=$(cat)

transcript_path=$(echo "$input" | jq --raw-output '.transcript_path // empty')
if [[ -z "$transcript_path" ]]; then
  exit 0
fi

if [[ ! -f "$transcript_path" ]]; then
  exit 0
fi

# Extract the last assistant entry's text content blocks (skip thinking + tool_use).
# grep without --only-matching returns the full JSONL line so jq gets a complete object.
text=$(
  grep '"type":"assistant"' "$transcript_path" |
    tail --lines=1 |
    jq --raw-output '
        .message.content
        | if type == "array" then .
          else []
          end
        | map(select(.type == "text" and .text != null))
        | map(.text)
        | join("\n")
      ' 2>/dev/null || true
)

if [[ -z "$text" ]]; then
  # Tool-only turn or no assistant content — exit silently.
  exit 0
fi

# Strip markdown so symbols aren't spoken aloud.
# Steps:
# 1. Multi-line fenced code blocks (``` ... ```) — delete entire fence sections
# 2. Inline backtick spans
# 3. Markdown links [text](url) → keep text only
# 4. Bare URLs
# 5. Bold/italic markers (* ** __ but NOT underscores inside identifiers)
# 6. Headings (#)
# 7. Leading list markers (- or * at line start)
# 8. Remaining lone backticks
# shellcheck disable=SC2016
cleaned=$(
  printf '%s' "$text" |
    sed --regexp-extended '/^```/,/^```/d' |
    sed --regexp-extended 's/`[^`]*`//g' |
    sed --regexp-extended 's/\[([^]]*)\]\([^)]*\)/\1/g' |
    sed --regexp-extended 's|https?://[^ \t\n)>"]*||g' |
    sed --regexp-extended 's/\*\*([^*]*)\*\*/\1/g' |
    sed --regexp-extended 's/\*([^*]*)\*/\1/g' |
    sed --regexp-extended 's/__([^_]*)__/\1/g' |
    sed --regexp-extended 's/(^|[[:space:]])_([^_[:space:]][^_]*)_([[:space:]]|$)/\1\2\3/g' |
    sed --regexp-extended 's/^#{1,6} //g' |
    sed --regexp-extended 's/^[[:space:]]*[-*] //g' |
    sed --regexp-extended 's/`//g'
)

if [[ -z "$(echo "$cleaned" | tr --delete '[:space:]')" ]]; then
  exit 0
fi

# Cap at 2000 characters to avoid very long reads.
if [[ ${#cleaned} -gt 2000 ]]; then
  cleaned="${cleaned:0:2000}… (message truncated)"
fi

# Overlap guard: kill any in-flight speech process group before starting a new one.
# We use setsid to put the speech child in its own process group and store the PGID.
# On the next invocation we kill -- -$pgid to reach the entire group (espeak-ng,
# pw-play, say, etc.) — not just the subshell wrapper whose children would otherwise
# survive.
if [[ "$(uname --kernel-name)" == "Darwin" ]]; then
  pgid_file="/tmp/claude-speak.pgid"
else
  pgid_file="${XDG_RUNTIME_DIR:-/tmp}/claude-speak.pgid"
fi

if [[ -f "$pgid_file" ]]; then
  old_pgid=$(cat "$pgid_file" 2>/dev/null || true)
  if [[ -n "$old_pgid" ]]; then
    # Verify the group leader still exists before killing to avoid hitting a
    # recycled PGID.
    if kill -0 -- "-$old_pgid" 2>/dev/null; then
      kill -- "-$old_pgid" 2>/dev/null || true
    fi
  fi
  rm --force "$pgid_file"
fi

# Speak in a new session (setsid makes it a process-group leader); store its PGID.
# The PGID equals the PID of the setsid'd process, which we capture via $!.
if [[ "$(uname --kernel-name)" == "Darwin" ]]; then
  setsid /usr/bin/say "$cleaned" &
  speak_pid=$!
  echo "$speak_pid" >"$pgid_file"
  # Clean up pgid file when speech finishes naturally.
  {
    wait "$speak_pid" 2>/dev/null
    rm --force "$pgid_file"
  } &
else
  setsid bash -c 'espeak-ng --stdout "$1" | pw-play --target=0 -' -- "$cleaned" &
  speak_pid=$!
  echo "$speak_pid" >"$pgid_file"
  {
    wait "$speak_pid" 2>/dev/null
    rm --force "$pgid_file"
  } &
fi

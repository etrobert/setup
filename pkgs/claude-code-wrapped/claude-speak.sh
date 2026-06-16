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

# Strip markdown so symbols aren't spoken aloud:
# 1. Code fences (``` blocks)
# 2. Inline backticks
# 3. URLs (http/https)
# 4. Bold/italic markers (* ** _ __)
# 5. Headings (#)
# 6. Remaining backticks
cleaned=$(
  echo "$text" |
    sed --regexp-extended 's/```[^`]*```//g' |
    sed --regexp-extended 's/`[^`]*`//g' |
    sed --regexp-extended 's|https?://[^ \t\n)>"]*||g' |
    sed --regexp-extended 's/\*\*([^*]*)\*\*/\1/g' |
    sed --regexp-extended 's/\*([^*]*)\*/\1/g' |
    sed --regexp-extended 's/__([^_]*)__/\1/g' |
    sed --regexp-extended 's/_([^_]*)_/\1/g' |
    sed --regexp-extended 's/^#{1,6} //gm' |
    sed --regexp-extended 's/`//g'
)

if [[ -z "$(echo "$cleaned" | tr --delete '[:space:]')" ]]; then
  exit 0
fi

# Cap at 2000 characters to avoid very long reads.
if [[ ${#cleaned} -gt 2000 ]]; then
  cleaned="${cleaned:0:2000}… (message truncated)"
fi

# Overlap guard: kill any in-flight speech process before starting a new one.
if [[ "$(uname --kernel-name)" == "Darwin" ]]; then
  pid_file="/tmp/claude-speak.pid"
else
  pid_file="${XDG_RUNTIME_DIR:-/tmp}/claude-speak.pid"
fi

if [[ -f "$pid_file" ]]; then
  old_pid=$(cat "$pid_file" 2>/dev/null || true)
  if [[ -n "$old_pid" ]] && kill --signal 0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null || true
  fi
  rm --force "$pid_file"
fi

# Speak in a background subshell; write its PID for future overlap-guard checks.
if [[ "$(uname --kernel-name)" == "Darwin" ]]; then
  (
    /usr/bin/say "$cleaned"
    rm --force "$pid_file"
  ) &
  echo "$!" >"$pid_file"
else
  (
    espeak-ng --stdout "$cleaned" | pw-play --target=0 -
    rm --force "$pid_file"
  ) &
  echo "$!" >"$pid_file"
fi

#!/usr/bin/env bash
# Stop hook: read the final assistant message aloud via TTS.
# Set CLAUDE_SPEAK=0 to mute without rebuilding.

if [[ "${CLAUDE_SPEAK:-}" == "0" ]]; then
  exit 0
fi

input=$(cat)

text=$(echo "$input" | jq --raw-output '.last_assistant_message // empty')

if [[ -z "$text" ]]; then
  # Tool-only turn or no assistant content — exit silently.
  exit 0
fi

# Strip markdown so symbols aren't spoken aloud.
# SC2016: the sed regexes below contain literal backticks, which shellcheck
# mistakes for command substitution; they are regex literals, not expansions.
# shellcheck disable=SC2016
cleaned=$(
  printf '%s' "$text" |
    # Delete entire multi-line fenced code blocks (``` ... ```), including indented ones.
    sed --regexp-extended '/^[[:space:]]*```/,/^[[:space:]]*```/d' |
    # Inline backtick code spans (`code`) → keep the text, drop the backticks.
    sed --regexp-extended 's/`([^`]*)`/\1/g' |
    # Markdown links [text](url) → keep the link text, drop the URL.
    sed --regexp-extended 's/\[([^]]*)\]\([^)]*\)/\1/g' |
    # Remove bare URLs (http:// or https://).
    sed --regexp-extended 's|https?://[^ \t\n)>"]*||g' |
    # Strip bold markers (**text**), keeping the text.
    sed --regexp-extended 's/\*\*([^*]*)\*\*/\1/g' |
    # Strip italic markers (*text*), keeping the text.
    sed --regexp-extended 's/\*([^*]*)\*/\1/g' |
    # Strip bold underscore markers (__text__), keeping the text.
    sed --regexp-extended 's/__([^_]*)__/\1/g' |
    # Strip italic underscore markers (_text_) but NOT underscores inside identifiers.
    sed --regexp-extended 's/(^|[[:space:]])_([^_[:space:]][^_]*)_([[:space:]]|$)/\1\2\3/g' |
    # Remove heading markers (# … ######) at line start.
    sed --regexp-extended 's/^#{1,6} //g' |
    # Remove leading list markers (- or * at line start).
    sed --regexp-extended 's/^[[:space:]]*[-*] //g' |
    # Remove any remaining lone backticks.
    sed --regexp-extended 's/`//g'
)

if [[ -z "$(echo "$cleaned" | tr --delete '[:space:]')" ]]; then
  exit 0
fi

# Cap at 2000 characters to avoid very long reads.
if [[ ${#cleaned} -gt 2000 ]]; then
  cleaned="${cleaned:0:2000}… (message truncated)"
fi

# Overlap guard: kill any in-flight speech before starting a new one.
#
# Platform strategies differ because the speech pipeline differs:
#
# Linux: espeak-ng | pw-play is a two-process pipeline. We use setsid to place
#   both in a new process group, store the PGID, and use kill -- -$pgid on the
#   next invocation to reach the entire group.
#
# Darwin: /usr/bin/say is a single process — no child pipeline — so setsid is
#   not needed (and does not exist on macOS). We background it directly and
#   store its PID, then kill that PID with a kill -0 existence guard.

if [[ "$(uname --kernel-name)" == "Darwin" ]]; then
  pid_file="/tmp/claude-speak.pid"

  if [[ -f "$pid_file" ]]; then
    old_pid=$(cat "$pid_file" 2>/dev/null || true)
    if [[ -n "$old_pid" ]]; then
      if kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null || true
      fi
    fi
    rm --force "$pid_file"
  fi

  /usr/bin/say "$cleaned" &
  speak_pid=$!
  echo "$speak_pid" >"$pid_file"
  # Clean up pid file when speech finishes naturally.
  {
    wait "$speak_pid" 2>/dev/null
    rm --force "$pid_file"
  } &
else
  pgid_file="${XDG_RUNTIME_DIR:-/tmp}/claude-speak.pgid"

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

  # setsid creates a new session/process group; the pipeline (piper | pw-play)
  # inherits that PGID so kill -- -$pgid reaches both processes.
  # $BASH is the path to the current interpreter — avoids relying on bare "bash"
  # which is not in PATH when inheritPath = false.
  # piper reads text on stdin and writes a WAV (with header) to stdout via
  # --output_file -; pw-play autodetects the format from that header. PIPER_MODEL
  # is the vendored voice path exported by runtimeEnv; piper finds its .json
  # config next to the .onnx by adjacency (its --config flag is a no-op).
  # No --target: pw-play defaults to "auto", linking to the default sink.
  # (--target=0 means "don't link", which plays silently to nothing.)
  # SC2016: $PIPER_MODEL and $1 are intentionally single-quoted so the inner
  # shell (the setsid bash -c) expands them, not this outer one.
  # shellcheck disable=SC2016
  setsid "$BASH" -c \
    'piper --model "$PIPER_MODEL" --output_file - <<<"$1" | pw-play -' \
    -- "$cleaned" &
  speak_pid=$!
  echo "$speak_pid" >"$pgid_file"
  {
    wait "$speak_pid" 2>/dev/null
    rm --force "$pgid_file"
  } &
fi

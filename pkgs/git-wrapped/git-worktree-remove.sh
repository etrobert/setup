#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

WORKTREE_PATH="$1"

# Ask tmux which session sits here rather than deriving the name: the session
# is the thing being killed, and matching on its path cannot disagree with
# whatever tmux-sessionizer called it.
SESSION_NAME=$(tmux list-sessions -F '#{session_path}	#{session_name}' 2>/dev/null |
  awk -F'\t' -v path="$WORKTREE_PATH" '$1 == path { print $2; exit }')

if [ -n "$SESSION_NAME" ]; then
  tmux kill-session -t "$SESSION_NAME"
fi

git worktree remove "$WORKTREE_PATH"

echo "Cleaned up ${SESSION_NAME:-$WORKTREE_PATH}"

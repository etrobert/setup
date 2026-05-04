#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

WORKTREE_PATH="$1"

if [ -z "$WORKTREE_PATH" ]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

SESSION_NAME=$(basename "$WORKTREE_PATH")

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux kill-session -t "$SESSION_NAME"
fi

git worktree remove "$WORKTREE_PATH"

echo "Cleaned up $SESSION_NAME"

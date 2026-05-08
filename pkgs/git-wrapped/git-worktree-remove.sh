#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

WORKTREE_PATH="$1"

SESSION_NAME=$(basename "$WORKTREE_PATH")

# Kill tmux session if it exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux kill-session -t "$SESSION_NAME"
fi

# Remove worktree
git worktree remove "$WORKTREE_PATH"

echo "Cleaned up $SESSION_NAME"

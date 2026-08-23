#!/usr/bin/env bash

set -euo pipefail

# Resolve to the worktree root before deriving anything from it: the usual call
# is `git-worktree-remove` from inside the worktree.
WORKTREE_PATH=$(git -C "${1:-.}" rev-parse --show-toplevel)

# Ask tmux which session sits here rather than deriving the name, so it cannot
# disagree with whatever tmux-sessionizer called it. Empty outside tmux.
SESSION_NAME=$(tmux list-sessions -f "#{==:#{session_path},$WORKTREE_PATH}" \
  -F '#{session_name}' 2>/dev/null || true)

# Remove before killing: when the session is the one we are running in, the
# kill takes this script down with it.
git -C "$WORKTREE_PATH" worktree remove "$WORKTREE_PATH"

if [ -n "$SESSION_NAME" ]; then
  tmux kill-session -t "=$SESSION_NAME"
fi

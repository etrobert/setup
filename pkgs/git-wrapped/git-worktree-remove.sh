#!/usr/bin/env bash

set -euo pipefail

# Resolve to the worktree root before deriving anything from it: the usual call
# is `git-worktree-remove .` from inside, and tmux reads a bare "." as the
# session/window separator, i.e. the *current* session.
WORKTREE_PATH=$(git -C "${1:-.}" rev-parse --show-toplevel)

SESSION_NAME=$(basename "$WORKTREE_PATH")

# Remove before killing: when the session is the one we are running in, the
# kill takes this script down with it.
git -C "$WORKTREE_PATH" worktree remove "$WORKTREE_PATH"

tmux kill-session -t "=$SESSION_NAME" 2>/dev/null || true

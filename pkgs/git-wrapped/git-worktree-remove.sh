#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

WORKTREE_PATH="$1"

SESSION_NAME=$(basename "$WORKTREE_PATH")

# Read before the worktree goes: it is where the branch is checked out, which
# is also why the branch can only be deleted afterwards.
BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current)

# Kill tmux session if it exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux kill-session -t "$SESSION_NAME"
fi

# Remove worktree
git worktree remove "$WORKTREE_PATH"

# --delete refuses a squash-merged branch, since squashing leaves its commits
# outside main's ancestry. Ask the PR before reaching for --force, so an
# unmerged branch survives.
if [ -n "$BRANCH" ] && ! git branch --delete "$BRANCH" 2>/dev/null; then
  if [ "$(gh pr view "$BRANCH" --json state --jq .state 2>/dev/null)" = MERGED ]; then
    git branch --delete --force "$BRANCH"
  else
    echo "Kept $BRANCH: not merged locally and no merged PR" >&2
  fi
fi

echo "Cleaned up $SESSION_NAME"

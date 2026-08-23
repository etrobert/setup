#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <worktree-name>"
  exit 1
fi

# The main worktree's own directory name, which is also what the sessionizer's
# -w picker derives a name from. `git remote get-url origin` disagrees with it
# for a clone whose directory was renamed, and both would then name the same
# worktree two different sessions.
MAIN_PATH=$(git worktree list --porcelain | head -1 | cut -d' ' -f2-)

REPO_NAME=$(basename "$MAIN_PATH")

BRANCH="$1"

NAME="$REPO_NAME/$BRANCH"

WORKTREE_PATH="$HOME/worktrees/$NAME"

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git worktree add "$WORKTREE_PATH" "$BRANCH"
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  git worktree add "$WORKTREE_PATH" "$BRANCH"
else
  git worktree add "$WORKTREE_PATH" -b "$BRANCH"
fi

for file in .env .tmux.conf; do
  if [ -f "$file" ]; then
    cp "$file" "$WORKTREE_PATH"
  fi
done

if [ -f ".claude/settings.local.json" ]; then
  mkdir -p "$WORKTREE_PATH/.claude"
  cp ".claude/settings.local.json" "$WORKTREE_PATH/.claude/"
fi

tmux-sessionizer "$NAME"

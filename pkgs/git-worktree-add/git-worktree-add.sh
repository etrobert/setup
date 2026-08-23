#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <worktree-name>"
  exit 1
fi

# The project root holds the bare repo and every worktree beside it, so the
# common dir's parent is it -- and that holds from inside any worktree.
ROOT=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")

BRANCH="$1"

NAME="$(basename "$ROOT")/$BRANCH"

WORKTREE_PATH="$ROOT/$BRANCH"

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

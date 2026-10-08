#!/usr/bin/env bash

DETACHED=()
if [ "${1:-}" = --detached ]; then
  DETACHED=(--detached)
  shift
fi

if [ $# -eq 0 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 [--detached] <worktree-name> [<start-point>]"
  exit 1
fi

# The project root holds the bare repo and every worktree beside it, so the
# common dir's parent is it -- and that holds from inside any worktree.
ROOT=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")

# Otherwise the worktree would land inside the checkout, silently.
if [ ! -d "$ROOT/.bare" ]; then
  echo "$ROOT is not a bare-repo project -- reclone it with git pc" >&2
  exit 1
fi

BRANCH="$1"

NAME="$(basename "$ROOT")/$BRANCH"

WORKTREE_PATH="$ROOT/$BRANCH"

# --no-track: tracking origin/main would aim the first push at a mismatched
# upstream; push.autoSetupRemote creates the branch's own instead.
if [ $# -eq 2 ]; then
  git worktree add "$WORKTREE_PATH" -b "$BRANCH" --no-track "$2"
# A branch that exists only on origin still resolves: worktree add tracks it.
elif git show-ref --verify --quiet "refs/heads/$BRANCH" ||
  git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  git worktree add "$WORKTREE_PATH" "$BRANCH"
else
  git worktree add "$WORKTREE_PATH" -b "$BRANCH"
fi

for file in .env .tmux.conf CLAUDE.local.md .claude/settings.local.json; do
  if [ -f "$file" ]; then
    cp --parents "$file" "$WORKTREE_PATH"
  fi
done

tmux-sessionizer "${DETACHED[@]}" "$NAME"

#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <repository-url> [project-name]"
  exit 1
fi

URL="$1"

NAME="${2:-$(basename "$URL" .git)}"

ROOT="$HOME/work/$NAME"

if [ -e "$ROOT" ]; then
  echo "$ROOT already exists" >&2
  exit 1
fi

git init --quiet --bare "$ROOT/.bare"
cd "$ROOT"

# Makes the root a repository too, so plumbing run from it works -- notably
# git-worktree-add reading the common dir. Anything needing a work tree does not.
echo "gitdir: ./.bare" >.git

# `git clone --bare` would leave remote.origin.fetch unset, so nothing writes
# refs/remotes and every later fetch silently updates nothing. `remote add`
# writes it, and keeps refs/heads to the one branch we check out.
git remote add origin "$URL"
git fetch origin

DEFAULT=$(git symbolic-ref --short refs/remotes/origin/HEAD)
BRANCH=${DEFAULT#origin/}

git worktree add "$BRANCH" --track -b "$BRANCH" "$DEFAULT"

echo "Cloned $NAME into $ROOT"

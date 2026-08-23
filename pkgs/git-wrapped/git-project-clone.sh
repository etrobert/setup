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

# Makes the root a repository too, so plumbing run from it works -- notably
# git-worktree-add reading the common dir. Anything needing a work tree does not.
echo "gitdir: ./.bare" >"$ROOT/.git"

# `git clone --bare` would leave remote.origin.fetch unset, so nothing writes
# refs/remotes and every later fetch silently updates nothing. `remote add`
# writes it, and keeps refs/heads to the one branch we check out.
git -C "$ROOT" remote add origin "$URL"
git -C "$ROOT" fetch origin

DEFAULT=$(git -C "$ROOT" symbolic-ref --short refs/remotes/origin/HEAD)

# The directory is always main; the branch in it is whatever the remote's HEAD
# is, so a repository still on master lands in main/ like every other project.
git -C "$ROOT" worktree add main --track -b "${DEFAULT#origin/}" "$DEFAULT"

echo "Cloned $NAME into $ROOT"

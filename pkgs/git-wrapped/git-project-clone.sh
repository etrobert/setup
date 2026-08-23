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

git clone --bare "$URL" "$ROOT/.bare"

# Makes the root a repository too, so git works when run from it rather than
# from a worktree -- git-worktree-add reads the common dir from anywhere.
echo "gitdir: ./.bare" >"$ROOT/.git"

# --bare leaves remote.origin.fetch unset, so nothing writes refs/remotes and
# every later fetch silently updates nothing.
git -C "$ROOT" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git -C "$ROOT" fetch origin

# The directory is always main; the branch in it is whatever the remote's HEAD
# is, so a repository still on master lands in main/ like every other project.
git -C "$ROOT" worktree add main "$(git -C "$ROOT" symbolic-ref --short HEAD)"

echo "Cloned $NAME into $ROOT"

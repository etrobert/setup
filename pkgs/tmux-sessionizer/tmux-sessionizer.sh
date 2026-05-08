#!/usr/bin/env bash

set -euo pipefail

# Inspired by https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer

if [ $# -eq 1 ]; then
  case "$1" in
  -h | --help)
    echo "Usage: tmux-sessionizer [OPTIONS] [PROJECT_NAME]"
    echo ""
    echo "Create or switch to tmux sessions for projects."
    echo ""
    echo "OPTIONS:"
    echo "  -e, --existing    Show only existing tmux sessions"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "If no PROJECT_NAME is provided, shows a fuzzy finder with:"
    echo "  - Projects from ~/work/"
    echo "  - setup (this dotfiles repository)"
    echo ""
    echo "If PROJECT_NAME is provided, creates/switches to that session directly."
    exit 0
    ;;
  -e | --existing)
    project=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf)
    ;;
  *)
    project=$(echo "$1" | sed 's/\/$//')
    ;;
  esac
else
  project=$({
    find "$HOME/work" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
    echo "setup"
    echo "doc"
  } | fzf)
fi

if [ -z "$project" ]; then
  exit 0
fi

if [ "$project" = "setup" ]; then
  project_path=$HOME/setup
elif [ "$project" = "doc" ]; then
  project_path=$HOME/sync/doc
else
  project_path=$HOME/work/$project
fi

if [ ! -d "$project_path" ]; then
  echo "Error: $project_path does not exist" >&2
  exit 1
fi

project=${project/./_}

if ! tmux has-session -t="$project" 2>/dev/null; then
  tmux new-session -d -s "$project" -c "$project_path" -e "TMUX_SESSION_PATH=$project_path"
fi

if [ -v TMUX ]; then
  tmux switch-client -t "$project"
else
  tmux attach-session -t "$project"
fi

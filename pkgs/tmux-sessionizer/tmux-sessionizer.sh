#!/usr/bin/env bash

set -euo pipefail

# Inspired by https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer

project_dir() {
  case "$1" in
  setup) printf '%s' "$HOME/setup" ;;
  doc) printf '%s' "$HOME/sync/doc" ;;
  *) printf '%s' "$HOME/work/$1" ;;
  esac
}

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
    project=$(tmux list-sessions -F "#{session_name}" 2>/dev/null |
      fzf --preview 'tmux capture-pane -ep -t {}' --preview-window 'right:60%')
    ;;
  *)
    project=$(echo "$1" | sed 's/\/$//')
    ;;
  esac
else
  project=$({
    find "$HOME/work" -mindepth 1 -maxdepth 1 -type d -printf '%f\t%p\n'
    printf 'setup\t%s\n' "$(project_dir setup)"
    printf 'doc\t%s\n' "$(project_dir doc)"
  } | fzf \
    --delimiter '\t' \
    --with-nth 1 \
    --preview 'eza --tree --level=2 --color=always {2} 2>/dev/null || ls {2}' \
    --preview-window 'right:60%')
  project=${project%%$'\t'*}
fi

if [ -z "$project" ]; then
  exit 0
fi

project_path=$(project_dir "$project")

if [ ! -d "$project_path" ]; then
  echo "Error: $project_path does not exist" >&2
  exit 1
fi

project=${project//./_}

if ! tmux has-session -t="$project" 2>/dev/null; then
  tmux new-session -d -s "$project" -c "$project_path" -e "TMUX_SESSION_PATH=$project_path"
fi

if [ -v TMUX ]; then
  tmux switch-client -t "$project"
else
  tmux attach-session -t "$project"
fi

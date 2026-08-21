# Inspired by https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer

project_dir() {
  case "$1" in
  setup) printf '%s' "$HOME/setup" ;;
  doc) printf '%s' "$HOME/sync/doc" ;;
  *) printf '%s' "$HOME/work/$1" ;;
  esac
}

# Colours what fzf shows: blocked shouts, finished invites, working recedes,
# agent-less stays at the default. Reads "<name>|<marker> <name>" lines and
# colours only the second field, so the caller still gets a clean name back.
color_by_agent_state() {
  yellow=$'\e[1;33m'
  green=$'\e[32m'
  dim=$'\e[2m'
  reset=$'\e[0m'

  while IFS='|' read -r name display; do
    case $display in
    '!'*) printf '%s|%s%s%s\n' "$name" "$yellow" "$display" "$reset" ;;
    '✓'*) printf '%s|%s%s%s\n' "$name" "$green" "$display" "$reset" ;;
    '•'*) printf '%s|%s%s%s\n' "$name" "$dim" "$display" "$reset" ;;
    *) printf '%s|%s\n' "$name" "$display" ;;
    esac
  done
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
    echo "  -w, --worktrees   Show git worktrees of the current repository"
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
    # The preview is a real pane, not fzf's: every cursor move respawns it with
    # a read-only client attached to the highlighted session, so it shows the
    # session live. $TMUX has to go or tmux refuses to nest the client, so the
    # socket it names is passed on explicitly.
    socket=${TMUX%%,*}
    viewer=$(tmux split-window -h -d -l '60%' -P -F '#{pane_id}' 'sleep infinity')
    trap 'tmux kill-pane -t "$viewer" 2>/dev/null || true' EXIT

    # Field 2 is shown (agent marker, then the name), field 1 is the bare name
    # --accept-nth returns. The shown field goes last because a non-final one
    # carries its trailing delimiter into the display, and --delimiter is a
    # regex, hence the escaped pipe. p1 pads the marker so that sessions
    # without an agent still line their names up. Our own session is filtered
    # out — the viewer would render itself.
    project=$(tmux list-sessions -F '#{session_name}|#{p1:#{W:#{@agent-status}}} #{session_name}' \
      -f "#{!=:#{session_name},$(tmux display-message -p '#{session_name}')}" 2>/dev/null |
      color_by_agent_state |
      fzf --ansi --delimiter '\|' --with-nth 2 --accept-nth 1 \
        --bind "focus:execute-silent(tmux respawn-pane -k -t $viewer \"TMUX= tmux -S $socket attach -r -t {1}\")")
    project_path=""
    ;;
  -w | --worktrees)
    worktrees=$(git worktree list)

    main_path=${worktrees%%$'\n'*}
    main_path=${main_path%% *}

    # shellcheck disable=SC2016 # $FZF_PREVIEW_COLUMNS expands in fzf's preview shell
    selection=$(printf '%s\n' "$worktrees" | tail --lines +2 |
      fzf --preview 'DFT_COLOR=always DFT_WIDTH=$FZF_PREVIEW_COLUMNS \
          git -C {1} dlog --color=always origin/HEAD.. 2>/dev/null |
          grep . || git -C {1} log --oneline --color=always --max-count 15' \
        --preview-window 'right:60%')
    project_path=${selection%% *}
    project="$(basename "$main_path")/$(basename "$project_path")"
    ;;
  *)
    project=$(echo "$1" | sed 's/\/$//')
    project_path=$(project_dir "$project")
    ;;
  esac
else
  selection=$({
    find "$HOME/work" -mindepth 1 -maxdepth 1 -type d \
      ! -name setup ! -name doc -printf '%f\t%p\n'
    printf 'setup\t%s\n' "$(project_dir setup)"
    printf 'doc\t%s\n' "$(project_dir doc)"
  } | fzf \
    --delimiter '\t' \
    --with-nth 1 \
    --preview 'eza --tree --level=2 --color=always {2} 2>/dev/null || ls {2}' \
    --preview-window 'right:60%')
  project=${selection%%$'\t'*}
  project_path=${selection#*$'\t'}
fi

if [ -z "$project" ]; then
  exit 0
fi

session=${project//./_}

if ! tmux has-session -t="$session" 2>/dev/null; then
  if [ ! -d "$project_path" ]; then
    echo "Error: $project_path does not exist" >&2
    exit 1
  fi

  tmux new-session -d -s "$session" -c "$project_path" -e "TMUX_SESSION_PATH=$project_path"
fi

if [ -v TMUX ]; then
  tmux switch-client -t "$session"
else
  tmux attach-session -t "$session"
fi

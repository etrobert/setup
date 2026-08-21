# Inspired by https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer

project_dir() {
  case "$1" in
  setup) printf '%s' "$HOME/setup" ;;
  doc) printf '%s' "$HOME/sync/doc" ;;
  *) printf '%s' "$HOME/work/$1" ;;
  esac
}

# Where the background fan-out leaves PR state, one file per branch so results
# can be picked up as they land rather than all at once.
pr_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-sessionizer/pr"

# Fetching PR state costs about 700ms per branch, far too slow to open a
# picker with. Fan out in the background instead: the list renders from
# whatever is already cached and gains the rest as it arrives.
# The $N inside the xargs payload are the child shell's positionals, not ours:
# $1 is the cache dir passed in, $2 and $3 are the worktree and branch xargs
# appends -- hence single quotes, and hence the waiver.
# shellcheck disable=SC2016
refresh_pr_cache() {
  mkdir --parents "$pr_cache_dir"

  tmux list-sessions -F '#{session_path}' 2>/dev/null |
    while read -r path; do
      branch=$(git -C "$path" branch --show-current 2>/dev/null) || continue
      [ -n "$branch" ] && printf '%s\t%s\n' "$path" "$branch"
    done |
    xargs --max-lines=1 --max-procs=8 sh -c '
      cd "$2" || exit 0
      cache="$1/$(echo "$3" | tr / %).json"
      # Via a temp file: the redirect alone would leave an empty one behind for
      # every branch with no PR, which reads as a broken entry rather than none.
      gh pr view "$3" --json number,state,isDraft,statusCheckRollup \
        > "$cache.tmp" 2>/dev/null && mv "$cache.tmp" "$cache" || { rm -f "$cache.tmp"; exit 0; }
      [ -n "${FZF_PORT:-}" ] &&
        curl --silent --request POST "localhost:$FZF_PORT" \
          --data "reload(tmux-sessionizer --list-sessions)" >/dev/null
    ' sh "$pr_cache_dir"
}

# Nerd Font glyphs, the same ones workmux picks: nf-oct-git_pull_request and
# friends for the state, nf-md-check_circle and friends for the check rollup.
# Written as escapes so the private-use codepoints survive any editor.
pr_glyph_open=$'\uF407'
pr_glyph_merged=$'\uF419'
pr_glyph_closed=$'\uF406'
pr_glyph_draft=$'\uF177'
check_glyph_ok=$'\U000F0134'
check_glyph_fail=$'\U000F0159'
check_glyph_pending=$'\U000F0520'

# "#847   " -- number, state, and one mark for the whole check rollup, so a
# failing branch is visible without opening anything.
pr_summary() {
  file="$pr_cache_dir/$(echo "$1" | tr / %).json"
  [ -s "$file" ] || return 0

  fields=$(jq --raw-output '
    (.statusCheckRollup // [] | map(.conclusion // .state)) as $checks
    | (if ($checks | length) == 0 then "none"
       elif ($checks | any(. == "FAILURE" or . == "TIMED_OUT" or . == "CANCELLED")) then "fail"
       elif ($checks | any(. == "PENDING" or . == "IN_PROGRESS")) then "pending"
       else "ok" end) as $checkState
    | [(.number | tostring), (if .isDraft then "DRAFT" else .state end), $checkState]
    | @tsv
  ' "$file" 2>/dev/null) || return 0
  [ -n "$fields" ] || return 0

  IFS=$'\t' read -r number state checks <<<"$fields"

  case $state in
  OPEN) state_part="$green$pr_glyph_open" ;;
  MERGED) state_part="$magenta$pr_glyph_merged" ;;
  CLOSED) state_part="$red$pr_glyph_closed" ;;
  DRAFT) state_part="$dim$pr_glyph_draft" ;;
  *) state_part="$dim?" ;;
  esac

  case $checks in
  ok) check_part=" $green$check_glyph_ok" ;;
  fail) check_part=" $red$check_glyph_fail" ;;
  pending) check_part=" $dim$check_glyph_pending" ;;
  *) check_part="" ;;
  esac

  printf '%s#%s %s%s%s' "$dim" "$number" "$state_part" "$check_part" "$reset"
}

# One row per session: agent marker, name, then PR state once it has arrived.
# Blocked shouts, finished invites, working recedes, agent-less stays plain.
# Only the shown field is coloured, so --accept-nth still returns a clean name.
yellow=$'\e[1;33m'
green=$'\e[32m'
magenta=$'\e[35m'
red=$'\e[31m'
dim=$'\e[2m'
reset=$'\e[0m'

list_sessions() {
  names=()
  markers=()
  paths=()
  width=0

  while IFS='|' read -r name marker path; do
    names+=("$name")
    markers+=("$marker")
    paths+=("$path")
    [ ${#name} -gt "$width" ] && width=${#name}
  done < <(tmux list-sessions -F '#{session_name}|#{p1:#{W:#{@agent-status}}}|#{session_path}' 2>/dev/null)

  for i in "${!names[@]}"; do
    case ${markers[i]} in
    '!') color=$yellow ;;
    '✓') color=$green ;;
    '•') color=$dim ;;
    *) color='' ;;
    esac

    branch=$(git -C "${paths[i]}" branch --show-current 2>/dev/null || true)
    pr=$(pr_summary "$branch")

    printf '%s|%s%1s %-*s%s %s\n' \
      "${names[i]}" "$color" "${markers[i]}" "$width" "${names[i]}" "$reset" "$pr"
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
  --refresh-pr-cache)
    # Internal: started by the picker so it inherits $FZF_PORT.
    refresh_pr_cache
    exit 0
    ;;
  --list-sessions)
    # Internal: how the picker re-renders itself as PR state arrives.
    list_sessions
    exit 0
    ;;
  -e | --existing)
    # Field 2 is shown (agent marker, name, PR state), field 1 is the bare name
    # --accept-nth returns. The shown field goes last because a non-final one
    # carries its trailing delimiter into the display, and --delimiter is a
    # regex, hence the escaped pipe.
    #
    # --id-nth names field 1 as each row's identity, which is what lets --track
    # keep the cursor on the same session across a reload; without it tracking
    # is index-based and does not survive one. --listen hands the fetch a port
    # on $FZF_PORT so it can push a reload the moment a result lands, rather
    # than us polling for one.
    project=$(list_sessions |
      fzf --ansi --delimiter '\|' --with-nth 2 --accept-nth 1 \
        --track --id-nth 1 --listen \
        --bind 'start:execute-silent(tmux-sessionizer --refresh-pr-cache &)' \
        --preview 'tmux capture-pane -ep -t {1}' --preview-window 'right:60%' \
        --bind 'every(0.2):refresh-preview')
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

# Inspired by https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer

# A project is a bare repo and its worktrees, so a name is the path tail:
# ~/work/<repo>/<branch> <-> <repo>/<branch>, and stripping the prefix is the
# exact inverse. Nothing is checked out at the project root. doc is a synced
# directory rather than a repo, so it is the only project not sitting in ~/work.
project_dir() {
  case "$1" in
  doc) printf '%s' "$HOME/sync/doc" ;;
  *) printf '%s' "$HOME/work/$1" ;;
  esac
}

# Every checkout is a worktree, so a bare project name means the one holding the
# default branch. doc and any other plain directory has none, and is itself.
with_worktree() {
  case "$1" in
  */*) printf '%s' "$1" ;;
  *)
    dir=$(project_dir "$1")

    if [ -d "$dir/.bare" ]; then
      branch=$(git -C "$dir" symbolic-ref --short refs/remotes/origin/HEAD)
      printf '%s/%s' "$1" "${branch#origin/}"
    else
      printf '%s' "$1"
    fi
    ;;
  esac
}

# Fetching PR state costs about 900ms per branch, far too slow to open a
# picker with. Fan out in the background instead: the list renders from
# whatever pronto has already cached and gains the rest as it arrives.
# pronto owns the cache -- it derives the key from the worktree's remote and
# branch, and skips the fetch when its entry is still fresh, so fanning out on
# every open is cheap.
# The $1 inside the payload is the session path xargs appends, not ours --
# hence single quotes, and hence the waiver.
# shellcheck disable=SC2016
refresh_pr_cache() {
  tmux list-sessions -F '#{session_path}' 2>/dev/null |
    xargs --max-lines=1 --max-procs=8 sh -c '
      # Compare what the row would say rather than the cache file: a rollup
      # gains fresh timestamps on every poll, and redrawing to show identical
      # rows costs a render and a UI block.
      before=$(pronto --pr-summary "$1")
      pronto --pr-refresh "$1"
      [ "$(pronto --pr-summary "$1")" = "$before" ] && exit 0

      # One reload per PR, so rows fill in as each lookup lands.
      [ -n "${FZF_PORT:-}" ] &&
        curl --silent --request POST "localhost:$FZF_PORT" \
          --data "reload(tmux-sessionizer --list-sessions)" >/dev/null
    ' sh
}

# Nerd Font glyphs, written as escapes so the private-use codepoints survive any
# editor. Codepoints checked against the font's own cmap rather than copied from
# a cheat sheet: several nearby ones are unrelated icons, and a wrong glyph
# still renders, so it fails silently.
pr_glyph_open=$'\U000F407'   # oct-git_pull_request
pr_glyph_merged=$'\U000F419' # oct-git_merge
pr_glyph_closed=$'\U000F4DC' # oct-git_pull_request_closed
pr_glyph_draft=$'\U000F4DD'  # oct-git_pull_request_draft
check_glyph_ok=$'\U000F05E0'      # md-check_circle
check_glyph_fail=$'\U000F0159'    # md-close_circle
check_glyph_pending=$'\U000F051F' # md-timer_sand

# "#847   " -- number, state, and one mark for the whole check rollup, so a
# failing branch is visible without opening anything. pronto reduces the rollup
# for both of us, so a row and a shell prompt cannot disagree about a PR.
pr_summary() {
  # No PR, no repository, no cache yet: pronto prints nothing and exits 0, so
  # emptiness alone carries "nothing to show". A non-zero exit is a crash, and
  # errexit will not propagate it out of two nested command substitutions --
  # nor would stderr be read, with fzf repainting over it. Say it in the row.
  if ! fields=$(pronto --pr-summary "$1"); then
    printf '%spronto?%s' "$red" "$reset"
    return 0
  fi
  [ -n "$fields" ] || return 0

  IFS=$'\t' read -r number state checks <<<"$fields"

  case $state in
  OPEN) state_part="$green$pr_glyph_open" ;;
  MERGED) state_part="$mauve$pr_glyph_merged" ;;
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

  # Close the dim before the glyphs: faint is an attribute, so a later colour
  # sets the hue but leaves the intensity down, and a failing rollup has to
  # shout. The number stays dim -- it is a label, not the signal.
  printf '%s#%s%s %s%s%s' "$dim" "$number" "$reset" "$state_part" "$check_part" "$reset"
}

# Ahead, behind and dirty, rendered by pronto so the row and the prompt cannot
# drift apart. A directory that is not a repository is empty output and exit 0;
# a crash is the same story as pr_summary, so say it in the row.
git_summary() {
  if ! state=$(pronto --git-summary "$1" 2>/dev/null); then
    printf '%spronto?%s' "$red" "$reset"
    return 0
  fi
  [ -n "$state" ] || return 0

  printf '%s%s%s' "$dim" "$state" "$reset"
}

# One row per session: agent marker, name, then PR state once it has arrived.
# Blocked shouts, finished invites, working recedes, agent-less stays plain.
# Only the shown field is coloured, so --accept-nth still returns a clean name.
# dim leads with 0 because it is an attribute, not a colour: on its own it
# dims whatever foreground the previous segment left set.
yellow=$'\e[1;33m'
green=$'\e[32m'
# GitHub renders a merged PR purple, and no ANSI slot holds one: Catppuccin
# maps magenta to pink (#f5bde6). Truecolor is the only way to the theme's
# actual purple, and tmux passes it through (Tc).
mauve=$'\e[38;2;198;160;246m' # catppuccin macchiato mauve #c6a0f6
red=$'\e[31m'
dim=$'\e[0;2m'
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

    pr=$(pr_summary "${paths[i]}")
    git=$(git_summary "${paths[i]}")

    printf '%s|%s%1s %-*s%s %s %s\n' \
      "${names[i]}" "$color" "${markers[i]}" "$width" "${names[i]}" "$reset" "$pr" "$git"
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
    echo "  -n, --next-waiting  Switch to the next agent blocked or finished"
    echo "  -e, --existing    Show only existing tmux sessions"
    echo "  -w, --worktrees   Show git worktrees of the current repository"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "If no PROJECT_NAME is provided, shows a fuzzy finder over the"
    echo "projects in ~/work/, plus doc."
    echo ""
    echo "PROJECT_NAME is <repo>/<branch>, naming one worktree of a project."
    echo "A bare <repo> means the worktree holding the default branch."
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
  -n | --next-waiting)
    read -r session window <<<"$(tmux display-message -p '#{session_name} #{window_id}')"

    # Blocked or finished -- the same two the status bar carries, since both
    # want you and only working does not. Not the window we are on either; tmux
    # does every test, so an empty answer is just that rather than a pipeline
    # that failed.
    wants_you="#{||:#{==:#{@agent-status},!},#{==:#{@agent-status},✓}}"
    target=$(tmux list-windows -a \
      -f "#{&&:$wants_you,#{!=:#{window_id},$window}}" \
      -F '#{session_name}:#{window_index}' | head --lines=1)
    [ -n "$target" ] || exit 0

    # A key binding runs us without a client of its own, so name the one showing
    # the session we are leaving; switch-client has nothing to move otherwise.
    client=$(tmux list-clients -t "$session" -F '#{client_name}' | head --lines=1)
    if [ -n "$client" ]; then
      tmux switch-client -c "$client" -t "$target"
    fi
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
    # The bare repo has no checkout to open; every real worktree is a peer
    # here, so nothing is skipped either.
    worktrees=$(git worktree list | grep --invert-match '(bare)$')

    # shellcheck disable=SC2016 # $FZF_PREVIEW_COLUMNS expands in fzf's preview shell
    selection=$(printf '%s\n' "$worktrees" |
      fzf --preview 'DFT_COLOR=always DFT_WIDTH=$FZF_PREVIEW_COLUMNS \
          git -C {1} dlog --color=always origin/HEAD.. 2>/dev/null |
          grep . || git -C {1} log --oneline --color=always --max-count 15' \
        --preview-window 'right:60%')
    project_path=${selection%% *}
    project=${project_path#"$HOME/work/"}
    ;;
  *)
    project=$(with_worktree "$(echo "$1" | sed 's/\/$//')")
    project_path=$(project_dir "$project")
    ;;
  esac
else
  selection=$({
    find "$HOME/work" -mindepth 1 -maxdepth 1 -type d ! -name doc -printf '%f\t%p\n'
    printf 'doc\t%s\n' "$(project_dir doc)"
  } | fzf \
    --delimiter '\t' \
    --with-nth 1 \
    --preview 'eza --tree --level=2 --color=always {2} 2>/dev/null || ls {2}' \
    --preview-window 'right:60%')
  project=$(with_worktree "${selection%%$'\t'*}")
  project_path=$(project_dir "$project")
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

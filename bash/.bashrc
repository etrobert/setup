#!/bin/bash

# Source: https://ghostty.org/docs/features/shell-integration
# Ghostty shell integration for Bash. This should be at the top of your bashrc!
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
  builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

PROMPT_COMMAND='history -a; precmd'

# Using GNU date both on linux (date) and mac (gdate)
if command -v gdate >/dev/null 2>&1; then
  DATE='gdate'
else
  DATE='date'
fi

export CMD_TIMER_MS=

preexec() {
  if [[ -z $CMD_TIMER_MS ]]; then
    CMD_TIMER_MS=$($DATE +%s%3N)
  fi
}

precmd() {
  if [[ -z $CMD_TIMER_MS ]]; then
    return
  fi

  local now
  now=$($DATE +%s%3N)
  export LAST_CMD_TIME=$((now - CMD_TIMER_MS))
  unset CMD_TIMER_MS
}

trap 'preexec' DEBUG

# PS1="${PS1_USER_HOST}${CYAN_COLOR}\w$RESET_COLOR\$(__git_ps1 ' (%s)') \$(__time_ps1)$ "
PS1="\$(pronto \$?)"

if [ -f "$HOME/.alias" ]; then
  source "$HOME/.alias"
fi

case $(uname) in
Darwin)
  source "$HOME/.alias.darwin"
  ;;
Linux)
  source "$HOME/.alias.linux"
  ;;
esac

# Enables git autocompletion
source "$HOME/.git-completion.bash"

# See https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
# Options are great but make it super slow
export GIT_PS1_SHOWDIRTYSTATE=
export GIT_PS1_SHOWSTASHSTATE=
export GIT_PS1_SHOWUNTRACKEDFILES=
export GIT_PS1_SHOWUPSTREAM="auto"

# Enables to have the current git repository shown in prompt
source "$HOME/.git-prompt.sh"

# Disable ctrl-s and ctrl-q
stty -ixon

# Bind Ctrl-F to edit command in editor
bind '"\C-f": edit-and-execute-command'

# Infinite history
HISTSIZE=
HISTFILESIZE=

# linux nvm setup
[ -f /usr/share/nvm/init-nvm.sh ] && source /usr/share/nvm/init-nvm.sh

# fzf key bindings and completion
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

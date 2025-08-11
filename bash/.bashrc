#!/bin/bash

# Source: https://ghostty.org/docs/features/shell-integration
# Ghostty shell integration for Bash. This should be at the top of your bashrc!
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
  builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

# Add brackets \[...\] around non printing characters
# To allow bash to properly calculate prompt size
# When calling external functions, \[ and \] should
# be replaced by \001 and \002 respectively
# Source: https://stackoverflow.com/questions/24839271/bash-ps1-line-wrap-issue-with-non-printing-characters-from-an-external-command
#PS1=' \u@\H \[\e[0;36m\]$(~/bin/pretty_pwd)\[\e[m\]$(__git_ps1 " (%s)")> '

PROMPT_COMMAND='precmd'

CYAN_COLOR='\001\e[0;36m\002'
RED_COLOR='\001\e[0;31m\002'
RESET_COLOR='\001\e[m\002'

# Uncomment to show user and host in prompt
# Use \H for the full hostname or \h for the hostname until the first dot
# PS1_USER_HOST='\u@\h '
PS1_USER_HOST=

export CMD_TIMER_MS=

preexec() {
  if [[ -z $CMD_TIMER_MS ]]; then
    CMD_TIMER_MS=$(gdate +%s%3N)
  fi
}

precmd() {
  EXIT_STATUS=$?
  if [[ -z $CMD_TIMER_MS ]]; then
    return
  fi

  local now
  now=$(gdate +%s%3N)
  export LAST_CMD_TIME=$((now - CMD_TIMER_MS))
  unset CMD_TIMER_MS
}

__time_ps1() {
  if [ "$EXIT_STATUS" -ne 0 ]; then
    printf "%b[%s]%b" "$RED_COLOR" "$EXIT_STATUS" "$RESET_COLOR"
  elif ((LAST_CMD_TIME < 100)); then
    # ex [01ms]
    # ex [99ms]
    printf "[%02dms]" "$LAST_CMD_TIME"
  elif ((LAST_CMD_TIME < 1000)); then
    # ex [.10s]
    # ex [.99s]
    printf "[.%ds]" "$((LAST_CMD_TIME / 10))"
  elif ((LAST_CMD_TIME < 60000)); then
    # ex [1.0s]
    # ex [59.9s]
    printf "[%d.%ds]" $((LAST_CMD_TIME / 1000)) $((LAST_CMD_TIME % 1000 / 100))
  else
    printf "[%dm%ds]" $((LAST_CMD_TIME / 60000)) $((LAST_CMD_TIME % 60000 / 1000))
  fi
}

trap 'preexec' DEBUG

PS1="${PS1_USER_HOST}${CYAN_COLOR}\w$RESET_COLOR\$(__git_ps1 ' (%s)') \$(__time_ps1)$ "

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
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWSTASHSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM="auto"

# Enables to have the current git repository shown in prompt
source "$HOME/.git-prompt.sh"

# Disable ctrl-s and ctrl-q
stty -ixon

# Infinite history
HISTSIZE=
HISTFILESIZE=

# Uncomment to show user and host in prompt
# PS1_USER_HOST='%n@%m '
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
    echo "%F{red}[$EXIT_STATUS]%f"
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

# Setting up prompt with timing
setopt PROMPT_SUBST
PS1=" ${PS1_USER_HOST}%F{cyan}%~%f \$(__time_ps1)$ "

if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

sourceifexists () {
  if [ -f $1 ]; then
    source $1
  fi
}

sourceifexists ~/.alias

alias mkls="make 2> /tmp/mkls_tmp || less /tmp/mkls_tmp"

case `uname` in
  Darwin)
    sourceifexists ~/.alias.darwin
  ;;
  Linux)
    sourceifexists ~/.alias.linux
  ;;
esac

# zsh sessions will append their history list to the history file
setopt APPEND_HISTORY
# Print the exit value of programs with non-zero exit status.
setopt PRINT_EXIT_VALUE
# Allow comments even in interactive shells.
setopt INTERACTIVE_COMMENTS

# Connection prompt
#if [ -f ~/work/scripts/login_tips.sh ]
#then
#	~/work/scripts/login_tips.sh
#fi
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# Load Homebrew config script
#if [ -f $HOME/.brewconfig.zsh ]
#then
#	source $HOME/.brewconfig.zsh
#fi

# Sets normal backspace behavior
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char

# Binds Ctrl-P/Ctrl-N to history search
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search

# Binds the zsh stuff to emacs like
bindkey -e

export CMD_TIMER_MS=

preexec() {
  if [[ -z $CMD_TIMER_MS ]]; then
    CMD_TIMER_MS=$(gdate +%s%3N)
  fi
}

precmd() {
  if [[ -z $CMD_TIMER_MS ]]; then
    return
  fi

  local now
  now=$(gdate +%s%3N)
  export LAST_CMD_TIME=$((now - CMD_TIMER_MS))
  unset CMD_TIMER_MS
}

# Setting up prompt with pronto
setopt PROMPT_SUBST
PS1='$(pronto $?)'

if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

sourceifexists() {
  if [ -f "$1" ]; then
    source "$1"
  fi
}

sourceifexists ~/.alias

alias mkls="make 2> /tmp/mkls_tmp || less /tmp/mkls_tmp"

case $(uname) in
Darwin)
  sourceifexists ~/.alias.darwin
  ;;
Linux)
  sourceifexists ~/.alias.linux
  ;;
esac

# Infinite history
HISTSIZE=999999999
SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history

# zsh sessions will append their history list to the history file
setopt APPEND_HISTORY
# Print the exit value of programs with non-zero exit status.
setopt PRINT_EXIT_VALUE
# Allow comments even in interactive shells.
setopt INTERACTIVE_COMMENTS

# Enable completion system
autoload -Uz compinit && compinit

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# Sets normal backspace behavior
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char

# Binds Ctrl-P/Ctrl-N to history search
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search

# Binds the zsh stuff to emacs like
bindkey -e

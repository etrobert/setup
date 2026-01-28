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

# Setting up prompt with pronto
setopt PROMPT_SUBST
PS1='$(pronto $? --zsh)'
RPROMPT='$(pronto $? --rprompt --zsh)'

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
# Allow comments even in interactive shells.
setopt INTERACTIVE_COMMENTS

# Enable completion system
autoload -Uz compinit && compinit

# Fish-like inline suggestions from history (zsh-autosuggestions)
sourceifexists /run/current-system/sw/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey "^Y" autosuggest-accept

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^F" edit-command-line

# Sets normal backspace behavior
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char

# Binds the zsh stuff to emacs like
# bindkey -e

# Binds the zsh stuff to vi like
bindkey -v

# Binds Ctrl-P/Ctrl-N to history search (after vi mode to override)
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search

bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

source <(fzf --zsh)

# Auto-start Hyprland on TTY1
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  start-hyprland
fi

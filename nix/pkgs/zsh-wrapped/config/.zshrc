typeset -U path cdpath fpath manpath

# Use viins keymap as the default.
bindkey -v

setopt INTERACTIVE_COMMENTS

setopt APPEND_HISTORY
HISTSIZE="999999999"
SAVEHIST="999999999"

HISTFILE="$HOME/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"

export CMD_TIMER_MS=

preexec() {
  if [[ -z $CMD_TIMER_MS ]]; then
    CMD_TIMER_MS=$(date +%s%3N)
  fi
}

precmd() {
  if [[ -z $CMD_TIMER_MS ]]; then
    return
  fi

  local now
  now=$(date +%s%3N)
  export LAST_CMD_TIME=$((now - CMD_TIMER_MS))
  unset CMD_TIMER_MS
}

# needed over enableCompletion = true; to avoid errors on mac
autoload -Uz compinit && compinit -i

setopt PROMPT_SUBST
PS1='$(pronto $? --zsh)'
RPROMPT='$(pronto $? --rprompt --zsh)'

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^F" edit-command-line

bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char

# Override vi mode defaults: Ctrl-P/N for history search
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search

bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

bindkey "^Y" autosuggest-accept

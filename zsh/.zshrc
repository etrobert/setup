# Setting up prompt
PS1="%T %n@%m:%~> "
#autoload -Uz promptinit
#promptinit
#prompt adam2

if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

if [ -f ~/.alias ]; then
  source ~/.alias
fi

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

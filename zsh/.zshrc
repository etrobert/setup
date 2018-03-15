# Setting up prompt
PS1="%T %n@%m:%~> "
#autoload -Uz promptinit
#promptinit
#prompt adam2

if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

sourceifexists () {
  if [ -f $1 ]; then
    source $1
  fi
}

sourceifexists ~/.alias

alias mkls="make 2> tmp || less tmp"

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

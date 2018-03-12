# Setting up prompt
PS1="%T %n@%m:%~> "
#autoload -Uz promptinit
#promptinit
#prompt adam2

# Aliases
alias ls="ls -F"
alias mv="mv -i"
alias cp="cp -i"
alias getmake="cp ~/work/tools/ctools/Makefile ."
alias getmain="cp ~/work/tools/ctools/main.c ."
alias getctools="getmake ; getmain"
alias getcpptools="cp ~/work/tools/cpptools/Makefile ~/work/tools/cpptools/main.cpp ."
alias LS="echo try again"
alias sl="echo try again"
alias rm="rm -v"
alias mkls="make 2> tmp || less tmp"
alias make="make -j8"

if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi

case `uname` in
  Darwin)
    # commands for OS X go here
    alias ctags="`brew --prefix`/bin/ctags"
  ;;
  Linux)
    # commands for Linux go here
  ;;
  FreeBSD)
    # commands for FreeBSD go here
  ;;
esac

# 42 Aliases
#alias 42FileChecker="sh ~/42FileChecker/42FileChecker.sh"
#alias qno="norminette | grep -B1 Error"

# git aliases
alias gs="git status"
alias gc="git commit"
alias ga="git add"
alias gp="git push"
alias gpl="git pull"
alias gd="git diff"

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

PS1='\u@\H \e[0;36m$(~/bin/pretty_pwd)\e[m> '
if [ -f ~/.alias ]; then
  source ~/.alias
fi

# Disable ctrl-s and ctrl-q
stty -ixon

# Infinite history
HISTSIZE= HISTFILESIZE=

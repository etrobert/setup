# Add brackets \[...\] around non printing characters
# To allow bash to properly calculate prompt size
PS1='\u@\H \[\e[0;36m\]$(~/bin/pretty_pwd)\[\e[m\]> '

if [ -f ~/.alias ]; then
  source ~/.alias
fi

case $(uname) in
Darwin)
  source ~/.alias.darwin
  ;;
Linux)
  source ~/.alias.linux
  ;;
esac

# Disable ctrl-s and ctrl-q
stty -ixon

# Infinite history
HISTSIZE= HISTFILESIZE=

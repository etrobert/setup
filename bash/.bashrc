# Add brackets \[...\] around non printing characters
# To allow bash to properly calculate prompt size
PS1=' \u@\H \[\e[0;36m\]$(~/bin/pretty_pwd)\[\e[m\]$(__git_ps1 " (%s)")> '

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

# Enables git autocompletion
source ~/.git-completion.bash
# Enables to have the current git repository shown in prompt
source ~/.git-prompt.sh

# Disable ctrl-s and ctrl-q
stty -ixon

# Infinite history
HISTSIZE= HISTFILESIZE=

# Add brackets \[...\] around non printing characters
# To allow bash to properly calculate prompt size
# When calling external functions, \[ and \] should
# be replaced by \001 and \002 respectively
# Source: https://stackoverflow.com/questions/24839271/bash-ps1-line-wrap-issue-with-non-printing-characters-from-an-external-command
#PS1=' \u@\H \[\e[0;36m\]$(~/bin/pretty_pwd)\[\e[m\]$(__git_ps1 " (%s)")> '
PS1=' \u@\H \001\e[0;36m\002\w\001\e[m\002$(__git_ps1 " (%s)")> '

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

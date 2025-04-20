# Add brackets \[...\] around non printing characters
# To allow bash to properly calculate prompt size
# When calling external functions, \[ and \] should
# be replaced by \001 and \002 respectively
# Source: https://stackoverflow.com/questions/24839271/bash-ps1-line-wrap-issue-with-non-printing-characters-from-an-external-command
#PS1=' \u@\H \[\e[0;36m\]$(~/bin/pretty_pwd)\[\e[m\]$(__git_ps1 " (%s)")> '

PROMPT_COMMAND='EXIT_STATUS=$?;'

CYAN_COLOR='\001\e[0;36m\002'
RED_COLOR='\001\e[0;31m\002'
RESET_COLOR='\001\e[m\002'

PS1_ERROR_CODE='$(if [ $EXIT_STATUS -ne 0 ]; then echo " '$RED_COLOR'[$EXIT_STATUS]'$RESET_COLOR'"; fi)'

# Uncomment to show user and host in prompt
# Use \H for the full hostname or \h for the hostname until the first dot
# PS1_USER_HOST='\u@\h '
PS1_USER_HOST=

PS1=' '$PS1_USER_HOST$CYAN_COLOR'\w'$RESET_COLOR'$(__git_ps1 " (%s)")'$PS1_ERROR_CODE'$ '

if [ -f "$HOME/.alias" ]; then
  source "$HOME/.alias"
fi

case $(uname) in
Darwin)
  source "$HOME/.alias.darwin"
  ;;
Linux)
  source "$HOME/.alias.linux"
  ;;
esac

# Enables git autocompletion
source "$HOME/.git-completion.bash"

# See https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWSTASHSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM="auto"

# Enables to have the current git repository shown in prompt
source "$HOME/.git-prompt.sh"

# Disable ctrl-s and ctrl-q
stty -ixon

# Infinite history
HISTSIZE=
HISTFILESIZE=

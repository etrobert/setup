# Uncomment the line below to print every command run by the shell
# set -x

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Load env variables from ~/.env
# We actually want the word splitting here
# shellcheck disable=SC2046
[ -f ~/.env ] && export $(grep -v '^#' ~/.env | xargs)

PATH=/usr/local/bin:$PATH
PATH="/usr/local/opt/python/libexec/bin:$PATH"

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi

# homebrew setup
# generated with `/opt/homebrew/bin/brew shellenv`
if [ -d "/opt/homebrew" ]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
  MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
  INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
  export HOMEBREW_NO_ANALYTICS=1
fi

# Enables Rust
if [ -d /opt/homebrew/opt/rustup/bin ]; then
  PATH="/opt/homebrew/opt/rustup/bin:$PATH"
fi

export EDITOR=vim
# export BROWSER=firefox
export MAIL=etiennerobert33@gmail.com

# Activate touch support in firefox
export MOZ_USE_XINPUT2=1

# opam configuration
test -r /home/etienne/.opam/opam-init/init.sh && . /home/etienne/.opam/opam-init/init.sh >/dev/null 2>/dev/null || true

# nvm configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# rbenv configuration
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# pnpm
if [ -d "$HOME/Library/pnpm" ]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  export PATH="$PNPM_HOME:$PATH"
fi
# pnpm end

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
if [ -d "$HOME/.pyenv" ]; then
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

[ -f "/Users/etiennerobert/.ghcup/env" ] && . "/Users/etiennerobert/.ghcup/env" # ghcup-env

export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

# pipx and cursor-cli
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$PATH:$HOME/.local/bin"
fi

if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

# raycast scripts
if [ -d "$HOME/.config/raycast/scripts" ]; then
  export PATH="$PATH:$HOME/.config/raycast/scripts"
fi

# disable claude code auto updates
# source: https://formulae.brew.sh/cask/claude-code
export DISABLE_AUTOUPDATER=1

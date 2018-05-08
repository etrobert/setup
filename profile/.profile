# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/bin" ] ; then
    PATH=$PATH:~/brew/bin
fi

PATH=$PATH:~/work/scripts
# Searches for brew libs/binaries before system ones
PATH=/usr/local/bin:$PATH
PATH="/usr/local/opt/python/libexec/bin:$PATH"

# Enables Rust
if [ -d "$HOME/bin" ] ; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

export EDITOR=vim
#export MAIL=etrobert@student.42.fr
export MAIL=erobert@scortex.io

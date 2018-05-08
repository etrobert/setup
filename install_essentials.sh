#!/bin/sh

# stow needs to be installed
# vundle has to be installed manually

stow alias profile zsh bash git ssh vim tmux
chmod 600 ssh/.ssh/config

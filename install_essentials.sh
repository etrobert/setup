#!/bin/sh

# stow needs to be installed

stow alias profile fish zsh bash readline git ssh vim tmux && \
chmod 600 ssh/.ssh/config

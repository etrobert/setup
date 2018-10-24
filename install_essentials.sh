#!/bin/sh

# stow needs to be installed

stow alias profile fish zsh bash git ssh vim tmux && \
chmod 600 ssh/.ssh/config

# vundle has to be installed manually
# git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

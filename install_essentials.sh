#!/bin/sh

# stow needs to be installed

stow alias profile bash readline git ssh vim tmux &&
  chmod 600 ssh/.ssh/config

if [ "$(uname)" == "Darwin" ]; then
  # Install brew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  brew install --cask alacritty
fi

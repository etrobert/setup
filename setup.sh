#!/bin/sh

set -e

setup_homebrew() {
  echo "Setting up Homebrew..."

  if [ -d "/opt/homebrew" ]; then
    echo "Homebrew is already installed."
  else
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  echo "Adding Homebrew to PATH..."
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

setup_stow() {
  echo "Setting up GNU Stow..."

  if command -v stow >/dev/null; then
    echo "GNU Stow is already installed."
  else
    echo "GNU Stow not found. Installing GNU Stow..."
    brew install stow
  fi
}

setup_dotfiles() {
  echo "Setting up dotfiles..."

  stow alias bash ghostty git macos nvim profile readline ssh tmux

  echo "Setting proper permissions for SSH config..."
  chmod 600 ssh/.ssh/config
}

setup_homebrew
setup_stow
setup_dotfiles

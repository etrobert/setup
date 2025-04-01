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

setup_ssh_key() {
  echo "Setting up SSH key..."

  if [ -f "$HOME/.ssh/id_ed25519" ]; then
    echo "SSH key already exists."
    return
  fi

  echo "SSH key not found. Generating SSH key..."
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ''
}

setup_github() {
  echo "Setting up GitHub..."

  if command -v gh >/dev/null; then
    echo "GitHub CLI is already installed."
  else
    echo "GitHub CLI not found. Installing GitHub CLI..."
    brew install gh
  fi

  echo 'Authenticating GitHub CLI...'

  if gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is already authenticated."
  else
    echo "GitHub CLI not authenticated. Authenticating..."
    gh auth login
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
setup_ssh_key
setup_github
# setup_dotfiles

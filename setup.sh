#!/bin/sh

set -e

ensure_installed() {
  echo "Checking if $1 is installed..."

  if command -v "$1" >/dev/null; then
    echo "$1 is already installed."
  else
    echo "$1 not found. Installing $1..."
    brew install "$1"
  fi
}

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

  ensure_installed gh

  echo 'Authenticating GitHub CLI...'

  if gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is already authenticated."
  else
    echo "GitHub CLI not authenticated. Authenticating..."
    gh auth login --git-protocol ssh --hostname github.com --web
  fi
}

setup_dotfiles() {
  echo "Setting up dotfiles..."

  ensure_installed stow

  if [ -d "$HOME/setup" ]; then
    echo "Dotfiles repository already cloned."
  else
    echo "Dotfiles repository not found. Cloning dotfiles repository..."
    git clone git@github.com:etrobert/setup.git "$HOME/setup"
  fi

  cd "$HOME/setup"

  echo "Stowing dotfiles..."
  stow alias bash ghostty git macos nvim profile readline ssh tmux

  echo "Setting proper permissions for SSH config..."
  chmod 600 ssh/.ssh/config
}

setup_applications() {
  echo "Setting up applications..."

  ensure_installed nvim
  ensure_installed tmux
}

setup_homebrew
echo
setup_ssh_key
echo
setup_github
echo
setup_dotfiles
echo
setup_applications

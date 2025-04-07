#!/bin/sh

set -e

# example: ensure_installed nvim
# example: ensure_installed ghostty --cask
ensure_installed() {
  echo "Checking if $1 is installed..."

  if brew list "$1" >/dev/null 2>&1; then
    echo "$1 is already installed."
  else
    echo "$1 not found. Installing $1..."
    if [ -n "$2" ]; then
      brew install "$2" "$1"
    else
      brew install "$1"
    fi
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

  ensure_installed neovim
  ensure_installed tmux
  ensure_installed difftastic
  ensure_installed fzf

  ensure_installed ghostty --cask
}

setup_shell() {
  echo "Setting up default shell"

  target_shell="/bin/bash"
  current_shell="$SHELL"

  if [ "$current_shell" = "$target_shell" ]; then
    echo "Your shell is already $target_shell."
  else
    chsh -s "$target_shell"
  fi
}

setup_capslock() {
  echo "Setting up Caps Lock as Control"

  if [ "$(hidutil property --get 'UserKeyMapping')" = "(null)" ]; then
    echo "No Keymaps, setting up..."
    hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'
  else
    echo "Caps Lock is already remapped as Control."
  fi
}

setup_node() {
  echo "Setting up Node.js..."

  if nvm --version >/dev/null 2>&1; then
    echo "NVM is already installed."
  else
    echo "NVM not found. Installing NVM..."
    PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash'
    . "$NVM_DIR/nvm.sh"
  fi

  echo "Installing Node.js..."
  if nvm ls node >/dev/null 2>&1; then
    echo "NodeJS is already installed."
  else
    nvm install node
  fi
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
echo
setup_shell
echo
setup_capslock
echo
setup_node

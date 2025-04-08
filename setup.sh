#!/bin/sh

set -e

# example: ensure_installed nvim
# example: ensure_installed ghostty --cask
ensure_installed() {
  echo "Checking if $1 is installed..."

  if brew list "$1" >/dev/null 2>&1; then
    echo "$1 is already installed."
    return
  fi

  echo "$1 not found. Installing $1..."
  if [ -n "$2" ]; then
    brew install "$2" "$1"
  else
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
    return
  fi

  echo "GitHub CLI not authenticated. Authenticating..."
  gh auth login --git-protocol ssh --hostname github.com --web
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
  ensure_installed arc --cask
  ensure_installed notion --cask
  ensure_installed spotify --cask
  ensure_installed slack --cask
  ensure_installed raycast --cask
  ensure_installed linear-linear --cask
}

setup_shell() {
  echo "Setting up default shell"

  target_shell="/bin/bash"
  current_shell="$SHELL"

  if [ "$current_shell" = "$target_shell" ]; then
    echo "Your shell is already $target_shell."
    return
  fi

  chsh -s "$target_shell"
}

setup_capslock() {
  echo "Setting up Caps Lock as Control"

  if [ "$(hidutil property --get 'UserKeyMapping')" != "(null)" ]; then
    echo "Caps Lock is already remapped as Control."
    return
  fi

  echo "No Keymaps, setting up..."
  hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'
}

setup_nvm() {
  echo "Setting up nvm..."

  if nvm --version >/dev/null 2>&1; then
    echo "NVM is already installed."
    return
  fi

  echo "NVM not found. Installing NVM..."
  PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash'
  . "$NVM_DIR/nvm.sh"
}

setup_node() {
  echo "Setting up Node.js..."

  if nvm ls node >/dev/null 2>&1; then
    echo "NodeJS is already installed."
    return
  fi

  echo "NodeJS not found. Installing..."
  nvm install node

  npm install -g corepack
}

setup_dock() {
  echo "Setting up dock..."

  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide -bool true

  # Clear existing items
  defaults write com.apple.dock persistent-apps -array

  add_app_to_dock() {
    app=$1
    if [ -e "$app" ]; then
      defaults write com.apple.dock persistent-apps -array-add "<dict>
      <key>tile-data</key>
      <dict>
        <key>file-data</key>
        <dict>
          <key>_CFURLString</key>
          <string>$app</string>
          <key>_CFURLStringType</key>
          <integer>0</integer>
        </dict>
      </dict>
    </dict>"
    else
      echo "Warning: $app not found. Skipping."
    fi
  }

  # Add applications in order
  add_app_to_dock "/System/Applications/Notes.app"
  add_app_to_dock "/System/Applications/System Settings.app"
  add_app_to_dock "/Applications/Arc.app/"
  add_app_to_dock "/Applications/Ghostty.app/"
  add_app_to_dock "/Applications/Slack.app/"
  add_app_to_dock "/System/Applications/Freeform.app/"
  add_app_to_dock "/Applications/Linear.app/"

  # Restart Dock to apply changes
  killall Dock
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
setup_nvm
echo
setup_node
echo
setup_dock

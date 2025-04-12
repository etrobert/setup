#!/bin/sh

set -e

START_TIME=$(date +%s)

ensure_gh_extension_installed() {
  echo "Checking if GitHub CLI extension $1 is installed..."

  if gh extension list | grep -q "$1"; then
    echo "GitHub CLI extension $1 is already installed."
  else
    echo "Installing GitHub CLI extension $1..."
    gh extension install "$1"
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

  brew bundle install --file="$HOME/setup/Brewfile"
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

  echo 'Authenticating GitHub CLI...'

  if gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is already authenticated."
  else
    echo "GitHub CLI not authenticated. Authenticating..."
    gh auth login --git-protocol ssh --hostname github.com --web
  fi

  ensure_gh_extension_installed meiji163/gh-notify
}

setup_dotfiles() {
  echo "Setting up dotfiles..."

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

  echo "Setting up variables..."
  # TODO: This crashes sometimes, need to investigate
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

  if [ -d "$NVM_DIR" ]; then
    echo "NVM is already installed."
  else
    echo "NVM not found. Installing NVM..."
    PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash'
  fi

  source "$NVM_DIR/nvm.sh"
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

  echo "Remove dock appearance delay"
  defaults write com.apple.dock autohide-delay -float 0
  echo "Setting dock to auto-hide"
  defaults write com.apple.dock autohide -bool true

  echo 'Clearing existing dock items'
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

  echo 'Adding applications to dock'
  add_app_to_dock "/System/Applications/Notes.app"
  add_app_to_dock "/System/Applications/System Settings.app"
  add_app_to_dock "/Applications/Arc.app/"
  add_app_to_dock "/Applications/Ghostty.app/"
  add_app_to_dock "/Applications/Slack.app/"
  add_app_to_dock "/System/Applications/Freeform.app/"
  add_app_to_dock "/Applications/Linear.app/"

  echo 'Restarting Dock to apply changes'
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
setup_shell
echo
setup_capslock
echo
setup_nvm
echo
setup_node
echo
setup_dock
echo

END_TIME=$(date +%s)

ELAPSED_TIME=$((END_TIME - START_TIME))
echo "Setup completed in ${ELAPSED_TIME} seconds"

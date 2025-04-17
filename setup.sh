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
  echo "Setting up Caps Lock as Control via LaunchAgent..."

  AGENT_LABEL="com.etienne.remapkeys"
  PLIST_PATH="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"

  if ! launchctl list | grep -q "$AGENT_LABEL"; then
    echo "Loading LaunchAgent..."
    launchctl bootstrap gui/$UID "$PLIST_PATH"
  else
    echo "LaunchAgent is already loaded."
  fi
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

  should_restart_dock=

  # Check and set autohide
  current_autohide=$(defaults read com.apple.dock autohide)
  if [ "$current_autohide" != "1" ]; then
    echo "Setting dock to auto-hide"
    defaults write com.apple.dock autohide -bool true
    should_restart_dock=true
  else
    echo "Dock auto-hide is already enabled"
  fi

  # Check and set autohide delay
  current_autohide_delay=$(defaults read com.apple.dock autohide-delay)
  if [ "$current_autohide_delay" != "0" ]; then
    echo "Removing dock appearance delay"
    defaults write com.apple.dock autohide-delay -float 0
    should_restart_dock=true
  else
    echo "Dock appearance delay is already set to 0"
  fi

  # Define desired apps
  desired_apps="
/System/Applications/Notes.app
/System/Applications/System%20Settings.app
/Applications/Arc.app/
/Applications/Ghostty.app/
/Applications/Slack.app/
/System/Applications/Freeform.app/
/Applications/Linear.app/
"

  # Check if we need to update apps
  current_apps=$(defaults read com.apple.dock persistent-apps)
  needs_app_update=

  # Get current apps paths
  current_apps_paths=$(defaults read com.apple.dock persistent-apps | grep '_CFURLString"' | sed 's/.*" = "\(.*\)"/\1/')

  # Check if current apps match desired apps
  for app in $desired_apps; do
    if ! echo "$current_apps_paths" | grep -q "$app"; then
      echo "Adding $app to dock"
      needs_app_update=true
      should_restart_dock=true
      break
    fi
  done

  if [ "$needs_app_update" ]; then
    echo 'Clearing existing dock items'
    defaults write com.apple.dock persistent-apps -array

    add_app_to_dock() {
      app=$1
      decoded_app=$(echo "$app" | sed 's/%20/ /g')
      if [ -e "$decoded_app" ]; then
        defaults write com.apple.dock persistent-apps -array-add "<dict>
        <key>tile-data</key>
        <dict>
          <key>file-data</key>
          <dict>
            <key>_CFURLString</key>
            <string>$decoded_app</string>
            <key>_CFURLStringType</key>
            <integer>0</integer>
          </dict>
        </dict>
      </dict>"
      else
        echo "Warning: $decoded_app not found. Skipping."
      fi
    }

    echo 'Adding applications to dock'
    for app in $desired_apps; do
      add_app_to_dock "$app"
    done
  else
    echo "Dock apps are already correctly configured"
  fi

  # Only restart dock if we made changes
  if [ "$should_restart_dock" ]; then
    echo 'Restarting Dock to apply changes'
    killall Dock
  fi
}

setup_trackpad() {
  echo "Setting up trackpad speed..."

  target_speed='2.5'

  set_trackpad_speed() {
    defaults write -g com.apple.trackpad.scaling "$target_speed"
    killall SystemUIServer
  }

  if ! current_speed=$(defaults read -g com.apple.trackpad.scaling 2>/dev/null); then
    echo 'Trackpad speed has not been set, setting...'
    set_trackpad_speed
    return
  fi

  if [ "$current_speed" = "$target_speed" ]; then
    echo 'Trackpad speed is already correctly set.'
    return
  fi

  echo 'Trackpad speed is wrong. Setting...'
  set_trackpad_speed
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
setup_trackpad
echo

END_TIME=$(date +%s)

ELAPSED_TIME=$((END_TIME - START_TIME))
echo "Setup completed in ${ELAPSED_TIME} seconds"

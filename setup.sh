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

setup_dotfiles_repo() {
  echo "Setting up dotfiles repo..."

  if [ -d "$HOME/setup" ]; then
    echo "Dotfiles repository already cloned."
    return
  fi
  echo "Dotfiles repository not found. Cloning dotfiles repository..."
  git clone git@github.com:etrobert/setup.git "$HOME/setup"

  echo "Setting proper permissions for SSH config..."
  chmod 600 "$HOME/setup/ssh/.ssh/config"
}

setup_darwin_dotfiles() {
  cd "$HOME/setup"

  echo "Stowing dotfiles..."
  stow alias bash ghostty git macos nvim profile readline ssh tmux skhd raycast prettier login claude
}

setup_linux_dotfiles() {
  cd "$HOME/setup"

  echo "Stowing dotfiles..."
  stow alias bash git nvim pacman profile readline ssh tmux claude
}

setup_rust() {
  echo "Installing rustup stuff components..."

  rustup default stable
  rustup component add rust-analyzer
}

setup_pronto() {
  mkdir -p $HOME/work
  git clone git@github.com:etrobert/pronto.git $HOME/work/pronto
  cd $HOME/work/pronto
  cargo install --path .
}

setup_shell() {
  echo "Setting up default shell"

  target_shell="/opt/homebrew/bin/bash"
  current_shell="$SHELL"

  if [ "$current_shell" = "$target_shell" ]; then
    echo "Your shell is already $target_shell."
    return
  fi

  # Add Homebrew shell to /etc/shells if not already there
  if ! grep -q "$target_shell" /etc/shells; then
    echo "Adding $target_shell to /etc/shells..."
    # Use tee with sudo because redirection doesn't work with sudo
    echo "$target_shell" | sudo tee -a /etc/shells >/dev/null
  else
    echo "$target_shell is already in /etc/shells"
  fi

  echo "Changing shell to $target_shell..."
  chsh -s "$target_shell"
}

setup_capslock() {
  echo "Setting up Caps Lock as Control via LaunchAgent..."

  AGENT_LABEL="com.etienne.remapkeys"
  PLIST_PATH="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"

  if ! launchctl list | grep -q "$AGENT_LABEL"; then
    echo "Loading LaunchAgent..."
    launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
  else
    echo "LaunchAgent is already loaded."
  fi
}

setup_capslock_linux() {
  echo "Setting up Caps Lock as Control via udev hwdb..."

  HWDB_FILE="/etc/udev/hwdb.d/90-custom-keyboard.hwdb"
  HWDB_CONTENT="evdev:input:b*v*p*
 KEYBOARD_KEY_3a=leftctrl"

  # Check if file exists and has correct content
  if [ -f "$HWDB_FILE" ]; then
    if grep -q "KEYBOARD_KEY_3a=leftctrl" "$HWDB_FILE"; then
      echo "Caps Lock remapping is already configured."
      return
    fi
  fi

  echo "Creating udev hwdb configuration..."
  echo "$HWDB_CONTENT" | sudo tee "$HWDB_FILE" > /dev/null

  echo "Updating hwdb database..."
  sudo systemd-hwdb update

  echo "Triggering udev reload..."
  sudo udevadm trigger
}

setup_nvm_install() {
  echo "Setting up nvm..."

  if [ -d "$NVM_DIR" ]; then
    echo "NVM is already installed."
    return
  fi

  echo "NVM not found. Installing NVM..."
  PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash'
}

setup_nvm() {
  # shellcheck disable=SC1091
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
}

setup_npm_packages() {
  echo "Installing global npm packages..."

  npm install -g \
    corepack \
    vscode-langservers-extracted \
    @github/copilot-language-server \
    @anthropic-ai/claude-code \
    bash-language-server \
    @tailwindcss/language-server \
    typescript-language-server \
    @fsouza/prettierd neonctl
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

  # Check and disable recents
  if ! defaults read com.apple.dock show-recents || [ "$(defaults read com.apple.dock show-recents)" != "0" ]; then
    echo "Disabling recent apps in dock"
    defaults write com.apple.dock show-recents -bool false
    should_restart_dock=true
  else
    echo "Dock recents are already disabled"
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
/Applications/Zen.app/
/Applications/Ghostty.app/
/Applications/Slack.app/
/Applications/Notion.app/
/Applications/Spotify.app/
/Applications/Linear.app/
/System/Applications/Notes.app
/System/Applications/System%20Settings.app
"

  # Check if we need to update apps
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

setup_skhd() {
  echo "Setting up skhd..."
  if [ -f "$HOME/Library/LaunchAgents/com.koekeishiya.skhd.plist" ]; then
    echo "skhd is already installed."
    return
  fi
  skhd --install-service
  skhd --start-service
}

setup_key_repeat() {
  echo "Setting up key repeat rates..."

  # Better key repeat rates
  current_key_repeat=$(defaults read NSGlobalDomain KeyRepeat)
  if [ "$current_key_repeat" != "2" ]; then
    echo "Setting faster key repeat rate"
    defaults write NSGlobalDomain KeyRepeat -int 2
    should_restart_ui=true
  else
    echo "Key repeat rate is already optimized"
  fi

  current_initial_repeat=$(defaults read NSGlobalDomain InitialKeyRepeat)
  if [ "$current_initial_repeat" != "15" ]; then
    echo "Setting shorter initial key repeat delay"
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    should_restart_ui=true
  else
    echo "Initial key repeat delay is already optimized"
  fi

  if [ "$should_restart_ui" ]; then
    echo "Note: Key repeat changes will take effect after logout/restart"
  fi
}

setup_yay() {
  echo 'Setting up yay'

  if which yay >/dev/null 2>&1; then
    echo 'yay is already installed'
    return
  fi

  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd ..
  rm -rf yay
}

setup_pacman_bundle() {
  echo 'Setting up packages with pacman-bundle'

  # Need full path because this needs to run before we stow to install stow
  $HOME/setup/pacman/.local/bin/pacman-bundle install
}

setup_darwin() {
  setup_homebrew
  echo
  setup_ssh_key
  echo
  setup_github
  echo
  setup_dotfiles_repo
  echo
  setup_darwin_dotfiles
  echo
  setup_shell
  echo
  setup_capslock
  echo
  setup_nvm_install
  echo
  setup_nvm
  echo
  setup_node
  echo
  setup_npm_packages
  echo
  setup_dock
  echo
  setup_trackpad
  echo
  setup_skhd
  echo
  setup_key_repeat
  echo
  setup_rust
  echo
}

setup_linux() {
  setup_ssh_key
  echo
  setup_github
  echo
  setup_dotfiles_repo
  echo
  setup_yay
  echo
  setup_pacman_bundle
  echo
  setup_linux_dotfiles
  echo
  setup_capslock_linux
  echo
  setup_nvm_install
  echo
  setup_nvm
  echo
  setup_node
  echo
  setup_npm_packages
  echo
  setup_rust
  echo
  setup_pronto
  echo
}

case $(uname) in
Darwin)
  setup_darwin
  ;;
Linux)
  setup_linux
  ;;
esac

END_TIME=$(date +%s)

ELAPSED_TIME=$((END_TIME - START_TIME))
echo "Setup completed in ${ELAPSED_TIME} seconds"

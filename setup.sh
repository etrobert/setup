#!/bin/sh

set -e

START_TIME=$(date +%s)

setup_step() {
  name=$1
  check_func="check_$name"
  install_func="install_$name"

  printf "%s... " "$check_func"
  if $check_func; then
    echo "skipped"
    return
  fi
  printf "\n%s\n" "$install_func"
  $install_func
  echo "done"
}

check_homebrew() {
  [ -d "/opt/homebrew" ]
}

install_homebrew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

check_brew_path() {
  which brew >/dev/null 2>&1
}

install_brew_path() {
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

check_brew_bundle() {
  brew bundle check --file="$HOME/setup/Brewfile" >/dev/null
}

install_brew_bundle() {
  brew bundle install --file="$HOME/setup/Brewfile"
}

check_ssh_key() {
  [ -f "$HOME/.ssh/id_ed25519" ]
}

install_ssh_key() {
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ''
}

check_github() {
  gh auth status >/dev/null 2>&1
}

install_github() {
  gh auth login --git-protocol ssh --hostname github.com --web
}

check_gh_extensions() {
  gh extension list | grep -q "meiji163/gh-notify"
}

install_gh_extensions() {
  gh extension install meiji163/gh-notify
}

check_dotfiles_repo() {
  [ -d "$HOME/setup" ]
}

install_dotfiles_repo() {
  git clone git@github.com:etrobert/setup.git "$HOME/setup"
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

check_pronto() {
  [ -f "$HOME/.cargo/bin/pronto" ]
}

install_pronto() {
  mkdir -p "$HOME/work"
  git clone git@github.com:etrobert/pronto.git "$HOME/work/pronto"
  cd "$HOME/work/pronto"
  cargo install --path .
}

setup_swap() {
  echo "Setting up swap..."

  SWAP_FILE="/swapfile"
  SWAP_SIZE="8G"

  # Create swapfile if it doesn't exist
  if [ ! -f "$SWAP_FILE" ]; then
    echo "Creating ${SWAP_SIZE} swapfile at $SWAP_FILE..."
    sudo dd if=/dev/zero of="$SWAP_FILE" bs=1G count=8 status=progress

    echo "Setting swapfile permissions..."
    sudo chmod 600 "$SWAP_FILE"

    echo "Formatting swapfile..."
    sudo mkswap "$SWAP_FILE"
  else
    echo "Swapfile already exists."
  fi

  # Activate swap if not already active
  if ! swapon --show | grep -q "$SWAP_FILE"; then
    echo "Activating swap..."
    sudo swapon "$SWAP_FILE"
  else
    echo "Swap is already active."
  fi

  # Add to /etc/fstab if not already there
  if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "Adding swapfile to /etc/fstab for persistence..."
    echo "$SWAP_FILE none swap defaults 0 0" | sudo tee -a /etc/fstab >/dev/null
  else
    echo "Swapfile already in /etc/fstab."
  fi

  echo "Swap setup complete. Current swap status:"
  swapon --show
  free -h
}

TARGET_SHELL="/opt/homebrew/bin/bash"

check_shell() {
  [ "$SHELL" = "$TARGET_SHELL" ]
}

install_shell() {
  if ! grep -q "$TARGET_SHELL" /etc/shells; then
    echo "$TARGET_SHELL" | sudo tee -a /etc/shells >/dev/null
  fi

  chsh -s "$TARGET_SHELL"
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
  echo "$HWDB_CONTENT" | sudo tee "$HWDB_FILE" >/dev/null

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

  packages="corepack \
    vscode-langservers-extracted \
    @github/copilot-language-server \
    @anthropic-ai/claude-code \
    bash-language-server \
    @tailwindcss/language-server \
    typescript-language-server \
    @fsouza/prettierd \
    neonctl \
    bun"

  to_install=""

  for pkg in $packages; do
    if ! npm list -g "$pkg" >/dev/null 2>&1; then
      to_install="$to_install $pkg"
    else
      echo "$pkg already installed"
    fi
  done

  if [ -n "$to_install" ]; then
    npm install -g "$to_install"
  else
    echo "All packages already installed"
  fi
}

setup_dock_autohide() {
  # Check and set autohide
  current_autohide=$(defaults read com.apple.dock autohide)
  if [ "$current_autohide" = "1" ]; then
    echo "Dock auto-hide is already enabled"
    return
  fi
  echo "Setting dock to auto-hide"
  defaults write com.apple.dock autohide -bool true
  should_restart_dock=true
}

setup_dock_show_recents() {
  # Check and disable recents
  if defaults read com.apple.dock show-recents && [ "$(defaults read com.apple.dock show-recents)" = "0" ]; then
    echo "Dock recents are already disabled"
    return
  fi
  echo "Disabling recent apps in dock"
  defaults write com.apple.dock show-recents -bool false
  should_restart_dock=true
}

setup_dock_autohide_delay() {
  # Check and set autohide delay
  current_autohide_delay=$(defaults read com.apple.dock autohide-delay)
  if [ "$current_autohide_delay" = "0" ]; then
    echo "Dock appearance delay is already set to 0"
    return
  fi
  echo "Removing dock appearance delay"
  defaults write com.apple.dock autohide-delay -float 0
  should_restart_dock=true
}

setup_dock_persistent_apps() {
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

  if [ -z "$needs_app_update" ]; then
    echo "Dock apps are already correctly configured"
    return
  fi

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
}

setup_dock() {
  echo "Setting up dock..."

  should_restart_dock=

  setup_dock_autohide

  setup_dock_show_recents

  setup_dock_autohide_delay

  setup_dock_persistent_apps

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
  "$HOME/setup/pacman/.local/bin/pacman-bundle" install
}

setup_darwin() {
  setup_step homebrew
  setup_step brew_path
  setup_step brew_bundle
  setup_step ssh_key
  setup_step github
  setup_step gh_extensions
  setup_step dotfiles_repo
  echo
  setup_darwin_dotfiles
  echo
  setup_step shell
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
  setup_step ssh_key
  setup_step github
  setup_step gh_extensions
  setup_step dotfiles_repo
  setup_yay
  echo
  setup_pacman_bundle
  echo
  setup_linux_dotfiles
  echo
  setup_capslock_linux
  echo
  setup_swap
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
  setup_step pronto
  echo
}

full_setup() {
  case $(uname) in
  Darwin)
    setup_darwin
    ;;
  Linux)
    setup_linux
    ;;
  esac
}

if [ -n "$1" ]; then
  setup_step "$1"
else
  full_setup
fi

END_TIME=$(date +%s)

ELAPSED_TIME=$((END_TIME - START_TIME))
echo "Setup completed in ${ELAPSED_TIME} seconds"

#!/bin/sh

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

check_darwin_dotfiles() {
  false
}

install_darwin_dotfiles() {
  cd "$HOME/setup"
  stow alias bash brew claude ghostty git login macos nvim prettier profile raycast readline skhd ssh tmux zsh
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

CAPSLOCK_AGENT_LABEL="com.etienne.remapkeys"

check_capslock() {
  launchctl list | grep -q "$CAPSLOCK_AGENT_LABEL"
}

install_capslock() {
  launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/$CAPSLOCK_AGENT_LABEL.plist"
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
/Applications/Helium.app/
/Applications/Ghostty.app/
/Applications/Spotify.app/
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

TARGET_TRACKPAD_SPEED='2.5'

check_trackpad() {
  current_speed=$(defaults read -g com.apple.trackpad.scaling 2>/dev/null) || return 1
  [ "$current_speed" = "$TARGET_TRACKPAD_SPEED" ]
}

install_trackpad() {
  defaults write -g com.apple.trackpad.scaling "$TARGET_TRACKPAD_SPEED"
  killall SystemUIServer
}

check_skhd() {
  [ -f "$HOME/Library/LaunchAgents/com.koekeishiya.skhd.plist" ]
}

install_skhd() {
  skhd --install-service
  skhd --start-service
}

check_darwin_key_repeat() {
  current_key_repeat=$(defaults read NSGlobalDomain KeyRepeat)
  [ "$current_key_repeat" = "2" ]
}

install_darwin_key_repeat() {
  defaults write NSGlobalDomain KeyRepeat -int 2
  echo "Note: Key repeat changes will take effect after logout/restart"
}

check_darwin_initial_key_repeat() {
  current_initial_repeat=$(defaults read NSGlobalDomain InitialKeyRepeat)
  [ "$current_initial_repeat" = "15" ]
}

install_darwin_initial_key_repeat() {
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  echo "Note: Key repeat changes will take effect after logout/restart"
}

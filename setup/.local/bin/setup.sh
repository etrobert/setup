#!/bin/sh

set -e

START_TIME=$(date +%s)

setup_step() {
  name=$1
  check_func="check_$name"
  install_func="install_$name"

  printf "%s... " "$name"
  if $check_func; then
    echo "skipped"
    return
  fi
  echo "installing"
  $install_func
  echo "done"
}

check_ssh_key() {
  [ -f "$HOME/.ssh/id_ed25519" ]
}

install_ssh_key() {
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ''
}

check_ssh_controls() {
  [ -d "$HOME/.ssh/controls" ]
}

install_ssh_controls() {
  mkdir -p "$HOME/.ssh/controls"
  chmod 700 "$HOME/.ssh/controls"
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

check_linux_dotfiles() {
  false
}

install_linux_dotfiles() {
  cd "$HOME/setup"
  stow alias bash git nvim pacman profile readline ssh tmux claude
}

check_rust() {
  rustup component list --installed | grep -q rust-analyzer
}

install_rust() {
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

HWDB_FILE="/etc/udev/hwdb.d/90-custom-keyboard.hwdb"

check_capslock_linux() {
  [ -f "$HWDB_FILE" ] && grep -q "KEYBOARD_KEY_3a=leftctrl" "$HWDB_FILE"
}

install_capslock_linux() {
  HWDB_CONTENT="evdev:input:b*v*p*
 KEYBOARD_KEY_3a=leftctrl"

  echo "$HWDB_CONTENT" | sudo tee "$HWDB_FILE" >/dev/null
  sudo systemd-hwdb update
  sudo udevadm trigger
}

check_nvm_install() {
  [ -d "$NVM_DIR" ]
}

install_nvm_install() {
  PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash'
}

check_nvm() {
  false
}

install_nvm() {
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
}

check_node() {
  nvm ls node >/dev/null 2>&1
}

install_node() {
  nvm install node
}

NPM_PACKAGES="corepack \
  vscode-langservers-extracted \
  @github/copilot-language-server \
  @anthropic-ai/claude-code \
  bash-language-server \
  @tailwindcss/language-server \
  typescript-language-server \
  @fsouza/prettierd \
  neonctl \
  opencode-ai \
  bun"

check_npm_packages() {
  installed=$(npm list -g --depth=0 2>/dev/null)
  for pkg in $NPM_PACKAGES; do
    if ! echo "$installed" | grep -q "$pkg@"; then
      return 1
    fi
  done
  return 0
}

install_npm_packages() {
  # shellcheck disable=SC2086
  npm install -g $NPM_PACKAGES
}

check_timesyncd() {
  systemctl is-enabled systemd-timesyncd >/dev/null 2>&1
}

install_timesyncd() {
  sudo systemctl enable --now systemd-timesyncd.service
}

check_cpupower_sudoers() {
  sudo test -f "/etc/sudoers.d/cpupower"
}

install_cpupower_sudoers() {
  SUDOERS_CONTENT="# Allow cpupower frequency-set without password
$USER ALL=(ALL) NOPASSWD: /usr/bin/cpupower frequency-set *"

  echo "$SUDOERS_CONTENT" | sudo tee /etc/sudoers.d/cpupower >/dev/null
  sudo chmod 0440 /etc/sudoers.d/cpupower
}

check_cpupower_default() {
  [ -f "/etc/default/cpupower" ] && grep -q "governor='performance'" /etc/default/cpupower && systemctl is-enabled cpupower >/dev/null 2>&1
}

install_cpupower_default() {
  echo "governor='performance'" | sudo tee /etc/default/cpupower >/dev/null
  sudo systemctl enable cpupower
  sudo systemctl start cpupower
}

check_i2c_dev_module() {
  lsmod | grep -q i2c_dev && [ -f "/etc/modules-load.d/i2c.conf" ]
}

install_i2c_dev_module() {
  sudo modprobe i2c-dev
  echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf >/dev/null
}

check_docker_group() {
  groups | grep -q docker
}

install_docker_group() {
  sudo usermod -aG docker "$USER"
  echo "Note: You need to log out and back in for docker group changes to take effect"
}

check_yay() {
  which yay >/dev/null 2>&1
}

install_yay() {
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd ..
  rm -rf yay
}

check_pacman_bundle() {
  false
}

install_pacman_bundle() {
  # Need full path because this needs to run before we stow to install stow
  "$HOME/setup/pacman/.local/bin/pacman-bundle" install
}

setup_darwin() {
  . "$HOME/setup/setup/.local/bin/darwin-setup.sh"

  setup_step homebrew
  setup_step brew_path
  setup_step brew_bundle
  setup_step ssh_key
  setup_step ssh_controls
  setup_step github
  setup_step gh_extensions
  setup_step dotfiles_repo
  setup_step darwin_dotfiles
  setup_step shell
  setup_step capslock
  setup_step nvm_install
  setup_step nvm
  setup_step node
  setup_step npm_packages
  setup_dock
  echo
  setup_step trackpad
  setup_step skhd
  setup_step darwin_key_repeat
  setup_step darwin_initial_key_repeat
  setup_step rust
  setup_step pronto
}

setup_linux() {
  setup_step ssh_key
  setup_step ssh_controls
  setup_step github
  setup_step gh_extensions
  setup_step dotfiles_repo
  setup_step yay
  setup_step pacman_bundle
  setup_step linux_dotfiles
  setup_step capslock_linux
  setup_swap
  echo
  setup_step timesyncd
  setup_step cpupower_sudoers
  setup_step cpupower_default
  setup_step i2c_dev_module
  setup_step docker_group
  setup_step nvm_install
  setup_step nvm
  setup_step node
  setup_step npm_packages
  setup_step rust
  setup_step pronto
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

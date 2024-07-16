# Exit immediately if a command exits with a non-zero status
set -e

echo "➡ Installing Homebrew"
if [ -f /opt/homebrew/bin/brew ]; then
  echo "Homebrew is already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "➡ Installing Packages"
/opt/homebrew/bin/brew install stow gh

echo "➡ Generating SSH key"
if [ -f ~/.ssh/id_ed25519 ]; then
  echo "SSH key already exists"
else
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
fi

echo "➡ Installing Arc"
if [ -d "/Applications/Arc.app" ]; then
  echo "Arc Browser is already installed"
else
  echo "Please install Arc"
  echo "https://releases.arc.net/release/Arc-latest.dmg"

  read -rp "Press enter to continue"
fi

echo "➡ Please Install and configure the Bitwarden browser extension"
echo "https://chromewebstore.google.com/detail/bitwarden-password-manage/nngceckbapebfimnlniiiahkandclblb"
read -rp "Press enter to continue"

echo "➡ Adding SSH key to GitHub"
pbcopy <~/.ssh/id_ed25519.pub
echo "SSH key copied to clipboard. Please add it to GitHub."
echo "https://github.com/settings/keys"
read -rp "Press enter to continue"

echo "➡ Cloning dotfiles"
if [ -d ~/setup ]; then
  echo "dotfiles already cloned"
else
  git clone git@github.com:etrobert/setup.git
fi

echo "➡ Stowing dotfiles"
cd ~/setup
stow alias bash git alacritty macos nvim profile readline ssh tmux

# Exit immediately if a command exits with a non-zero status
set -e

echo "➡ Installing Homebrew"
if [ -f /opt/homebrew/bin/brew ]; then
  echo "Homebrew is already installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install stow
/opt/homebrew/bin/brew install stow

echo "➡ Generating SSH key"
if [ -f ~/.ssh/id_ed25519 ]; then
  echo "SSH key already exists"
else
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
fi

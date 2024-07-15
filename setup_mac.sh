# Exit immediately if a command exits with a non-zero status
set -e

# Install Homebrew
if [ -f /opt/homebrew/bin/brew ]; then
  echo "Homebrew is already installed"
else
  echo "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install stow
/opt/homebrew/bin/brew install stow

if [ -f ~/.ssh/id_ed25519 ]; then
  echo "SSH key already exists"
else
  echo "Generating SSH key"
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
fi

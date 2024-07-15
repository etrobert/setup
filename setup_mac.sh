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

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

echo "➡ Logging in to GitHub"
if /opt/homebrew/bin/gh auth status > /dev/null 2>&1; then
  echo "You are already logged in to GitHub CLI."
else
  echo "You are not logged in to GitHub CLI. Logging in now..."
  /opt/homebrew/bin/gh auth login --git-protocol ssh --web --skip-ssh-key
fi

echo "➡ Adding SSH key to GitHub"
/opt/homebrew/bin/gh ssh-key add ~/.ssh/id_ed25519.pub -t $(hostname)

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
  # Step 1: Download the Arc Browser DMG file
  curl -L "https://releases.arc.net/release/Arc-latest.dmg" -o Arc-latest.dmg

  # Step 2: Mount the DMG file
  hdiutil attach Arc-latest.dmg

  # Step 3: Copy the application to the Applications folder
  cp -r /Volumes/Arc/Arc.app /Applications/

  # Step 4: Unmount the DMG file
  hdiutil detach /Volumes/Arc

  # Step 5: Clean up
  rm Arc-latest.dmg
fi

echo "➡ Please Install and configure the Bitwarden browser extension"
read -p "Press enter to continue"
echo "Opening Arc..."
# TODO: Configure default browser then change this to just be open
open -a Arc "https://chromewebstore.google.com/detail/bitwarden-password-manage/nngceckbapebfimnlniiiahkandclblb"
read -p "Press enter to continue"

echo "➡ Logging in to GitHub"
if /opt/homebrew/bin/gh auth status > /dev/null 2>&1; then
  echo "You are already logged in to GitHub CLI."
else
  /opt/homebrew/bin/gh auth login --git-protocol ssh --web --skip-ssh-key
fi

echo "➡ Adding SSH key to GitHub"
/opt/homebrew/bin/gh ssh-key add ~/.ssh/id_ed25519.pub -t $(hostname)

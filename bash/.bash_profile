if [ "$(uname)" == "Darwin" ]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1
fi

. "$HOME/.profile"

# nvm configuration (breaks on zsh)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# ngrok completion (breaks on zsh)
if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

# If interactive shell
if [ -n "$PS1" ]; then
  # Source .bashrc if it exists
  if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
  fi
fi

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && command -v Hyprland &>/dev/null; then
  exec Hyprland
fi

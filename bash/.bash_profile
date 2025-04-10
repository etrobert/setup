if [ "$(uname)" == "Darwin" ]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1
fi

. "$HOME/.profile"

# If interactive shell
if [ -n "$PS1" ]; then
  # Source .bashrc if it exists
  if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
  fi
fi

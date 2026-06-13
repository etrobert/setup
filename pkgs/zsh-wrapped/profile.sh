# Sourced as .zprofile (login shells only) via pkgs/zsh-wrapped/default.nix.
# Being progressively migrated into Nix and retired -- see issue #229.

# homebrew setup
# generated with `/opt/homebrew/bin/brew shellenv`
if [ -d "/opt/homebrew" ]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"
  PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
  MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
  INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
  export HOMEBREW_NO_ANALYTICS=1
fi

# Source Home Manager session variables
# Necessary to add here because we overwrite the .profile with this file
if [ -f "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
  . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
fi

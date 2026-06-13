# Sourced as .zprofile (login shells only) via pkgs/zsh-wrapped/default.nix.
# Being progressively migrated into Nix and retired -- see issue #229.

# Source Home Manager session variables
# Necessary to add here because we overwrite the .profile with this file
if [ -f "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
  . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
fi

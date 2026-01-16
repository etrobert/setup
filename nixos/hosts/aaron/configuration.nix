{ pkgs, pronto, ... }:
{
  imports = [ ../../modules/common.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "etiennerobert";

  # Note: doc says not to include the admin user
  users.knownUsers = [ "etiennerobert" ];

  users.users.etiennerobert = {
    uid = 501;
    shell = pkgs.zsh;
  };

  environment.shells = [ pkgs.zsh ];

  environment.systemPackages = with pkgs; [ watch ];

  # macOS-specific settings
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 80;
    };

    finder = {
      ShowPathbar = true;
    };

    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.KeyRepeat = 2;
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}

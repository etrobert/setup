{ pkgs, pronto, ... }:
{
  imports = [ ../../modules/common.nix ];

  allowedUnfreePackages = [ "raycast" ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "soft";

  # Note: doc says not to include the admin user
  users.knownUsers = [ "soft" ];

  users.users.soft = {
    uid = 505;
    shell = pkgs.zsh;
    home = "/Users/soft";
  };

  environment.shells = [ pkgs.zsh ];

  environment.systemPackages = with pkgs; [
    watch
    raycast
    defaultbrowser
  ];

  system.activationScripts.postActivation.text = ''
    ${pkgs.defaultbrowser}/bin/defaultbrowser firefox
  '';

  # macOS-specific settings
  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
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

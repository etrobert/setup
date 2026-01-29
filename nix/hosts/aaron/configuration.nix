{ pkgs, pronto, ... }:
{
  imports = [ ../../modules/common.nix ];

  allowedUnfreePackages = [ "raycast" ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "soft";

  # Note: doc says not to include the admin user
  users.knownUsers = [
    "soft"
    "etiennerobert"
  ];

  users.users = {
    soft = {
      uid = 505;
      shell = pkgs.zsh;
      home = "/Users/soft";
    };

    etiennerobert = {
      uid = 501;
      shell = pkgs.zsh;
      home = "/Users/etiennerobert";
    };
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

    CustomUserPreferences."com.raycast.macos" = {
      # Cmd + Space
      raycastGlobalHotkey = "Command-49";
    };

    CustomUserPreferences."com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # Disable Spotlight search shortcut (Cmd + Space)
        "64" = {
          enabled = false;
        };
      };
    };
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # TODO: Remove once mac uses the same username
  age.secrets.openai-api-key.group = "admin";
  age.secrets.openai-api-key.mode = "0440";
  age.secrets.gemini-api-key.group = "admin";
  age.secrets.gemini-api-key.mode = "0440";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}

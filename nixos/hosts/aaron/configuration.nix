{ pkgs, pronto, ... }:
{
  imports = [ ../../modules/common.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "etiennerobert";

  # Darwin-specific packages (if needed)
  # environment.systemPackages = with pkgs; [ ];

  # macOS-specific settings
  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 80;
    };
    #   finder.AppleShowAllExtensions = true;
    #   NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.KeyRepeat = 2;
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}

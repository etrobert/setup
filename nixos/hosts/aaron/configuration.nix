{ pkgs, pronto, ... }:
{
  imports = [ ../../modules/common.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    pronto.packages.${pkgs.stdenv.hostPlatform.system}.default
    bash-language-server
    bat # Cat(1) clone with syntax highlighting and Git integration
    btop
    claude-code
    difftastic
    eza
    fd
    fzf
    gcc
    gh
    git
    gnumake
    jq
    lua-language-server
    magic-wormhole # Securely transfer data between computers
    neovim
    nixd
    nodejs_latest
    prettierd
    ripgrep
    shfmt
    stow
    stylua
    tmux
    typescript-language-server
    vim
    wget
    zsh
  ];

  # fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  # macOS-specific settings
  # system.defaults = {
  #   dock.autohide = true;
  #   finder.AppleShowAllExtensions = true;
  #   NSGlobalDomain.AppleShowAllExtensions = true;
  #   NSGlobalDomain.InitialKeyRepeat = 15;
  #   NSGlobalDomain.KeyRepeat = 2;
  # };

  # Enable Touch ID for sudo
  # security.pam.enableSudoTouchIdAuth = true;

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}

{ pkgs, pronto, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    pronto.packages.${pkgs.stdenv.hostPlatform.system}.default
    adwaita-icon-theme
    bash-language-server
    bat
    btop
    claude-code
    difftastic
    eza
    fd
    fzf
    gcc
    gh
    # ghostty # https://github.com/ghostty-org/ghostty/discussions/4359
    git
    gnumake
    htop
    hyperfine # Command-line benchmarking tool
    jq
    libnotify
    lua-language-server
    magic-wormhole
    neovim
    nixd
    nixfmt
    nodejs_latest
    opencode
    prettierd
    ripgrep
    shellcheck
    shfmt
    spotify
    stow
    stylua
    tmux
    typescript-language-server
    vim
    wget
  ];

  programs.zsh.enable = true;

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];
}

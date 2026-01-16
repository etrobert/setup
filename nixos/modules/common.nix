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
    discord
    entr
    eza
    fd
    firefox
    fzf
    gcc
    gh
    # ghostty # https://github.com/ghostty-org/ghostty/discussions/4359
    git
    gnumake
    gopls
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
    ollama
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
    yt-dlp
  ];

  programs.zsh.enable = true;

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];
}

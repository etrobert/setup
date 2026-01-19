{ pkgs, pronto, ... }:
{
  imports = [ ./unfree.nix ];

  allowedUnfreePackages = [
    "claude-code"
    "discord"
    "spotify"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    pronto.packages.${pkgs.stdenv.hostPlatform.system}.default
    act
    adwaita-icon-theme
    audacity
    bash-language-server
    bat
    btop
    bun
    claude-code
    codex
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
    go
    gopls
    htop
    hyperfine # Command-line benchmarking tool
    imagemagick # for image rendering in nvim using snacks.image
    jq
    jqp # TUI playground to experiment with jq
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

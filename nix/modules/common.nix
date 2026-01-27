{
  agenix,
  lib,
  pkgs,
  pronto,
  ...
}:
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
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
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
    (writeShellApplication {
      name = "tmux-sessionizer";
      runtimeInputs = [
        coreutils
        gnused
        tmux
        fzf
        findutils
      ];
      text = builtins.readFile ../../tmux/.local/bin/tmux-sessionizer;
    })
    typescript-language-server
    vim
    wget
    yt-dlp
  ];

  age.secrets.openai-api-key = {
    file = ../secrets/openai-api-key.age;
    # TODO: Remove lib.mkDefault once the mac uses the same username
    owner = lib.mkDefault "soft";
  };

  age.secrets.gemini-api-key = {
    file = ../secrets/gemini-api-key.age;
    # TODO: Remove lib.mkDefault once the mac uses the same username
    owner = lib.mkDefault "soft";
  };

  programs.zsh.enable = true;

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];
}

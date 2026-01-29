{
  agenix,
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

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 10d";
  };

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
    codex # Lightweight coding agent that runs in your terminal
    difftastic
    discord
    entr
    eza
    fd
    fzf
    gcc
    gemini-cli # AI agent that brings the power of Gemini directly into your terminal
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
    (writeShellApplication {
      name = "gen-commit-msg";
      runtimeInputs = [
        coreutils
        curl
        git
        gnused
        jq
      ];
      inheritPath = false;
      text = builtins.readFile ../../git/.local/bin/gen-commit-msg;
    })
    (writeShellApplication {
      name = "git-find-commit";
      runtimeInputs = [
        coreutils
        git
        fzf
      ];
      inheritPath = false;
      text = builtins.readFile ../../git/.local/bin/git-find-commit;
    })
    typescript-language-server
    vim
    vscode-langservers-extracted
    wget
    yt-dlp
    zsh-autosuggestions # Fish shell autosuggestions for Zsh
    zsh-syntax-highlighting
  ];

  age.secrets.openai-api-key = {
    file = ../secrets/openai-api-key.age;
    owner = "soft";
  };
  age.secrets.gemini-api-key = {
    file = ../secrets/gemini-api-key.age;
    owner = "soft";
  };

  programs.zsh.enable = true;
  # Disable system compinit; we call compinit -u in .zshrc to skip
  # insecure directory warnings caused by Nix store paths.
  programs.zsh.enableGlobalCompInit = false;

  # Symlink zsh-syntax-highlighting to /run/current-system/sw/share/ (not included by default)
  environment.pathsToLink = [ "/share/zsh-syntax-highlighting" ];

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];
}

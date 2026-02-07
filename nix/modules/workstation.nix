{
  agenix,
  pkgs,
  pronto,
  ...
}:
{
  imports = [
    ./base.nix
    ./unfree.nix
  ];

  allowedUnfreePackages = [
    "claude-code"
    "discord"
    "spotify"
  ];

  environment.systemPackages = with pkgs; [
    pronto.packages.${pkgs.stdenv.hostPlatform.system}.default
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    act
    adwaita-icon-theme
    audacity
    bash-language-server
    bun
    chromium
    claude-code
    codex # Lightweight coding agent that runs in your terminal
    discord
    gcc
    gemini-cli # AI agent that brings the power of Gemini directly into your terminal
    # ghostty # https://github.com/ghostty-org/ghostty/discussions/4359
    gnumake
    go
    gopls
    home-manager
    hyperfine # Command-line benchmarking tool
    imagemagick # for image rendering in nvim using snacks.image
    jqp # TUI playground to experiment with jq
    libnotify
    lua-language-server
    nixd
    nodejs_latest
    ollama
    opencode
    prettierd
    spotify
    stylua
    tree-sitter
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
        findutils # xargs
      ];
      inheritPath = false;
      text = builtins.readFile ../../git/.local/bin/git-find-commit;
    })
    (writeShellApplication {
      name = "pm";
      runtimeInputs = [
        coreutils
        nodejs_latest
        pnpm
        yarn
      ];
      inheritPath = false;
      text = builtins.readFile ../../bash/.local/bin/pm;
    })
    typescript-language-server
    vscode-langservers-extracted
    yt-dlp
  ];

  age.secrets.openai-api-key = {
    file = ../secrets/openai-api-key.age;
    owner = "soft";
  };
  age.secrets.gemini-api-key = {
    file = ../secrets/gemini-api-key.age;
    owner = "soft";
  };

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];
}

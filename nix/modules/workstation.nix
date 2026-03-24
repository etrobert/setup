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
    "github-copilot-cli"
    "spotify"
  ];

  environment.systemPackages = with pkgs; [
    pronto.packages.${pkgs.stdenv.hostPlatform.system}.default
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    (symlinkJoin {
      name = "neovim-wrapped";
      buildInputs = [ makeWrapper ];
      paths = [ neovim ];
      postBuild = ''
        wrapProgram $out/bin/nvim \
          --prefix PATH : ${
            lib.makeBinPath [
              bash-language-server
              black # python formatter
              gopls
              imagemagick # for image rendering in nvim using snacks.image
              isort # python import sorter
              lua-language-server
              nixd
              nixfmt
              shfmt
              stylua
              tree-sitter
              typescript-language-server
              vscode-langservers-extracted
            ]
          }
      '';
    })
    act
    adwaita-icon-theme
    audacity
    bun
    claude-code
    codex # Lightweight coding agent that runs in your terminal
    discord
    gcc
    gemini-cli # AI agent that brings the power of Gemini directly into your terminal
    github-copilot-cli
    # ghostty # https://github.com/ghostty-org/ghostty/discussions/4359
    gnumake
    go
    home-manager
    hyperfine # Command-line benchmarking tool
    jqp # TUI playground to experiment with jq
    libnotify
    nodejs_24 # nodejs_latest does not always have cache ready
    ollama
    opencode
    pnpm
    prettierd
    python3
    spotify
    (writeShellApplication {
      name = "gen-commit-msg";
      runtimeInputs = [
        coreutils
        curl
        neovim # for editing the commit
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
        bashInteractive # provides sh for npm to spawn scripts
        coreutils
        nodejs_24 # nodejs_latest does not always have cache ready
        pnpm
        yarn
      ];
      inheritPath = true; # It may run anything through a npm script or vite thingy
      text = builtins.readFile ../../bash/.local/bin/pm;
    })
    (writeShellApplication {
      name = "pdfshrink";
      runtimeInputs = [ ghostscript ];
      inheritPath = false;
      text = builtins.readFile ../../pdfshrink/.local/bin/pdfshrink.sh;
    })
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

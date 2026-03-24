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

  environment.systemPackages =
    let
      neovim-wrapped = (
        pkgs.symlinkJoin {
          name = "neovim-wrapped";
          buildInputs = [ pkgs.makeWrapper ];
          paths = [ pkgs.neovim ];
          postBuild = ''
            wrapProgram $out/bin/nvim \
              --prefix PATH : ${
                pkgs.lib.makeBinPath (
                  with pkgs;
                  [
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
                )
              }
          '';
        }
      );

      gen-commit-msg = (
        pkgs.writeShellApplication {
          name = "gen-commit-msg";
          runtimeInputs = with pkgs; [
            coreutils
            curl
            neovim # for editing the commit
            git
            gnused
            jq
          ];
          inheritPath = false;
          text = builtins.readFile ../../git/.local/bin/gen-commit-msg;
        }
      );

      git-find-commit = (
        pkgs.writeShellApplication {
          name = "git-find-commit";
          runtimeInputs = with pkgs; [
            coreutils
            git
            fzf
            findutils # xargs
          ];
          inheritPath = false;
          text = builtins.readFile ../../git/.local/bin/git-find-commit;
        }
      );

      pm = (
        pkgs.writeShellApplication {
          name = "pm";
          runtimeInputs = with pkgs; [
            bashInteractive # provides sh for npm to spawn scripts
            coreutils
            nodejs_24 # nodejs_latest does not always have cache ready
            pnpm
            yarn
          ];
          inheritPath = true; # It may run anything through a npm script or vite thingy
          text = builtins.readFile ../../bash/.local/bin/pm;
        }
      );

      pdfshrink = (
        pkgs.writeShellApplication {
          name = "pdfshrink";
          runtimeInputs = with pkgs; [ ghostscript ];
          inheritPath = false;
          text = builtins.readFile ../../pdfshrink/.local/bin/pdfshrink.sh;
        }
      );
    in
    [
      pronto.packages.${pkgs.stdenv.hostPlatform.system}.default
      agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      neovim-wrapped
      gen-commit-msg
      git-find-commit
      pm
      pdfshrink
    ]
    ++ (with pkgs; [
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
      yt-dlp
    ]);

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

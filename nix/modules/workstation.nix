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
      neovim-wrapped = pkgs.symlinkJoin {
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
      };

      gen-commit-msg = import ../pkgs/gen-commit-msg.nix { inherit pkgs; };

      git-find-commit = pkgs.writeShellApplication {
        name = "git-find-commit";
        runtimeInputs = with pkgs; [
          coreutils
          git
          fzf
          findutils # xargs
        ];
        inheritPath = false;
        text = builtins.readFile ../../git/.local/bin/git-find-commit;
      };

      pm = import ../pkgs/pm.nix { inherit pkgs; };
      pdfshrink = import ../pkgs/pdfshrink.nix { inherit pkgs; };
      batr = import ../pkgs/batr.nix { inherit pkgs; };
      nixplatforms = import ../pkgs/nixplatforms.nix { inherit pkgs; };

      printline = pkgs.writeShellApplication {
        name = "printline";
        runtimeInputs = with pkgs; [ bat ];
        inheritPath = false;
        text = ''
          for _ in {1..80}; do echo -n '-'; done

          echo
        '';
      };
    in
    [

      pronto.packages.${pkgs.stdenv.hostPlatform.system}.default
      agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      neovim-wrapped
      gen-commit-msg
      git-find-commit
      pm
      pdfshrink
      nixplatforms
      batr
      printline
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

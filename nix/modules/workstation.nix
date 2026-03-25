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
      neovim-wrapped = import ../pkgs/neovim-wrapped.nix { inherit pkgs; };
      gen-commit-msg = import ../pkgs/gen-commit-msg.nix { inherit pkgs; };
      git-find-commit = import ../pkgs/git-find-commit.nix { inherit pkgs; };
      pm = import ../pkgs/pm.nix { inherit pkgs; };
      pdfshrink = import ../pkgs/pdfshrink.nix { inherit pkgs; };
      batr = import ../pkgs/batr.nix { inherit pkgs; };
      nixplatforms = import ../pkgs/nixplatforms.nix { inherit pkgs; };
      printline = import ../pkgs/printline.nix { inherit pkgs; };
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

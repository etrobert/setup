_: {
  flake = rec {
    nixosModules.workstation =
      {
        self,
        agenix,
        pkgs,
        pronto,
        ...
      }:
      {
        allowedUnfreePackages = [
          "claude-code"
          "discord"
          "github-copilot-cli"
          "spotify"
        ];

        environment.systemPackages =
          let
            inherit (pkgs.stdenv.hostPlatform) system;

            inputPackages = [
              pronto.packages.${system}.default
              agenix.packages.${system}.default
            ];

            customPackages = with self.packages.${system}; [
              alacritty-wrapped
              neovim-wrapped
              vscode-wrapped
              gen-commit-msg
              git-find-commit
              pm
              pdfshrink
              nixplatforms
              batr
              printline
              add-asset
            ];

            externalPackages = with pkgs; [
              act
              adwaita-icon-theme
              audacity
              btop
              bun
              # claude-code # cache not ready yet
              codex # Lightweight coding agent that runs in your terminal
              discord
              gcc
              gemini-cli # AI agent that brings the power of Gemini directly into your terminal
              gh
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
              python3
              shellcheck
              spotify
              unzip
              # yt-dlp # TODO: Add back once the macos cache is back
            ];
          in
          inputPackages ++ customPackages ++ externalPackages;

        age.secrets.openai-api-key = {
          file = ../secrets/openai-api-key.age;
          owner = "soft";
        };
        age.secrets.gemini-api-key = {
          file = ../secrets/gemini-api-key.age;
          owner = "soft";
        };

        fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

        programs.nix-index-database.comma.enable = true;

        programs.direnv.enable = true;

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };

    darwinModules.workstation = nixosModules.workstation;
  };
}

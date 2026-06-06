{ inputs, ... }:
{
  flake = rec {
    nixosModules.workstation =
      {
        self,
        agenix,
        pkgs,
        ...
      }:
      let
        # nixpkgs instance with the insecure permit dropped, used by the guard
        # below to detect when the permit is no longer load-bearing.
        pkgsStrict = import pkgs.path {
          inherit (pkgs.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
        electron39StillNeeded =
          !(builtins.tryEval (builtins.seq pkgsStrict.bitwarden-desktop.drvPath true)).success;
      in
      {
        allowedUnfreePackages = [
          "claude-code"
          "cmp-emoji"
          "discord"
          "github-copilot-cli"
          "google-chrome"
          "spotify"
        ];

        # bitwarden-desktop still pins electron 39 upstream, which nixpkgs now
        # marks EOL/insecure. The assertion below fails once it stops, so we
        # remember to drop this permit.
        nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

        assertions = [
          {
            assertion = electron39StillNeeded;
            message = "electron-39.8.10 is no longer pulled by bitwarden-desktop; remove the permittedInsecurePackages entry and this guard in modules/workstation.nix.";
          }
        ];

        environment.systemPackages =
          let
            inherit (pkgs.stdenv.hostPlatform) system;

            inputPackages = [ agenix.packages.${system}.default ];

            # bitwarden-desktop 2026.5.0 fails to build on darwin (its
            # electron-builder codesign step calls /usr/bin/security, absent in
            # the Nix sandbox), so darwin takes it from a pinned nixpkgs. Drop
            # the pin and this binding once upstream fixes the darwin build.
            bitwarden-desktop =
              if pkgs.stdenv.hostPlatform.isLinux then
                pkgs.bitwarden-desktop
              else
                inputs.nixpkgs-darwin-pins.legacyPackages.${system}.bitwarden-desktop;

            customPackages = with self.packages.${system}; [
              claude-code-wrapped
              claude-code-wrapped-glm
              claude-restart-daemon
              firefox-wrapped
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
              bitwarden-desktop
              btop
              bun
              discord
              ffmpeg
              gcc
              gemini-cli # AI agent that brings the power of Gemini directly into your terminal
              gh
              github-copilot-cli
              # ghostty # https://github.com/ghostty-org/ghostty/discussions/4359
              gnumake
              go
              google-chrome
              home-manager
              hyperfine # Command-line benchmarking tool
              jqp # TUI playground to experiment with jq
              libnotify
              nodejs_24 # nodejs_latest does not always have cache ready
              ollama
              opencode
              openscad-unstable
              pnpm
              python3
              shellcheck
              signal-desktop
              sox # Voice for claude
              spotify
              telegram-desktop
              unzip
              yt-dlp
            ];
          in
          inputPackages ++ customPackages ++ externalPackages;

        age.secrets = {
          openai-api-key = {
            file = ../secrets/openai-api-key.age;
            owner = "soft";
          };
          gemini-api-key = {
            file = ../secrets/gemini-api-key.age;
            owner = "soft";
          };
          github-bot-token = {
            file = ../secrets/github-bot-token.age;
            owner = "soft";
          };
          z-ai-auth-token = {
            file = ../secrets/z-ai-auth-token.age;
            owner = "soft";
          };
        };

        fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

        programs.direnv = {
          enable = true;
          settings.global.hide_env_diff = true;
        };

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };

    darwinModules.workstation = nixosModules.workstation;
  };
}

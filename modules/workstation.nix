_: {
  flake = rec {
    nixosModules.workstation =
      {
        self,
        config,
        lib,
        agenix,
        pkgs,
        ...
      }:
      {
        allowedUnfreePackages = [
          "claude-code"
          "cmp-emoji"
          "discord"
          "github-copilot-cli"
          "google-chrome"
          "spotify"
        ];

        environment.systemPackages =
          let
            inherit (pkgs.stdenv.hostPlatform) system;

            inputPackages = [ agenix.packages.${system}.default ];

            # leod's Intel UHD 620 can't hardware-decode AV1, so YouTube's AV1
            # streams software-decode and peg the CPU. Disabling it makes sites
            # serve VP9, which this GPU decodes in hardware. Drop when leod goes.
            firefox = self.packages.${system}.firefox-wrapped.override {
              extraSettings = lib.optionalAttrs (config.networking.hostName == "leod") {
                "media.av1.enabled" = false;
              };
            };

            customPackages = with self.packages.${system}; [
              claude-code-wrapped
              claude-code-wrapped-glm
              claude-restart-daemon
              firefox
              alacritty-wrapped
              neovim-wrapped
              vscode-wrapped
              claude-process-wrapper
              gen-commit-msg
              git-find-commit
              agents
              hass-cli-wrapped
              pm
              pdfshrink
              nixplatforms
              batr
              printline
              add-asset
              ils
            ];

            externalPackages = with pkgs; [
              act
              audacity
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
              nodejs_26 # pinned (not nodejs_latest) so the binary cache stays reliable
              opencode
              pnpm
              python3
              shellcheck
              signal-desktop
              sox # Voice for claude
              spotify
              telegram-desktop
              timg
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
          # Home Assistant long-lived access token, used by Claude Code to
          # query sensor data and call services over the LAN (http://tower:8123).
          hass-token = {
            file = ../secrets/hass-token.age;
            owner = "soft";
          };
          # Google Health API OAuth client credentials (the client secret JSON
          # downloaded from Google Cloud), used by Claude Code to read Fitbit Air
          # / health data. See the `google-health` skill (claude-code-wrapped
          # config) for the access recipe.
          google-health-oauth-client = {
            file = ../secrets/google-health-oauth-client.age;
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

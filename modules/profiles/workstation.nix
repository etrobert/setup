_: {
  flake = rec {
    nixosModules.workstation =
      {
        self,
        agenix,
        pkgs,
        ...
      }:
      {
        allowedUnfreePackages = [
          "claude-code"
          "cmp-emoji"
          "discord"
          "discord-unwrapped"
          "github-copilot-cli"
          "notion-app"
          "slack"
          "spotify"
        ];

        environment.systemPackages =
          let
            inherit (pkgs.stdenv.hostPlatform) system;

            inputPackages = [ agenix.packages.${system}.default ];

            customPackages = with self.packages.${system}; [
              aichat-wrapped
              claude-code-wrapped
              claude-code-wrapped-glm
              alacritty-wrapped
              neovim-wrapped
              vscode-wrapped
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
              ast-grep
              audacity

              # the rocm variant can dlopen ROCm SMI at runtime, which btop
              # needs to monitor AMD GPUs
              (if stdenv.hostPlatform.isLinux then btop-rocm else btop)

              bun
              discord
              ffmpeg
              gcc
              gh
              github-copilot-cli
              gnumake
              go
              hyperfine # Command-line benchmarking tool
              jqp # TUI playground to experiment with jq
              libnotify
              nodejs_26 # pinned (not nodejs_latest) so the binary cache stays reliable

              # Notion ships no official Linux client; notion-electron is the
              # community Electron wrapper around the web app.
              (if stdenv.hostPlatform.isDarwin then notion-app else notion-electron)

              opencode
              pnpm
              python3
              shellcheck
              signal-desktop
              slack
              sox # Voice for claude
              spotify
              telegram-desktop
              timg
              unzip
              yt-dlp
            ];
          in
          inputPackages ++ customPackages ++ externalPackages;

        # 30 github: inputs against an anonymous 60/hour-per-IP limit, shared by
        # every machine behind the same WAN address, is one `nix flake update`
        # away from exhaustion. `!include` is the tolerant form: nix skips it
        # when agenix has not decrypted yet, rather than failing to start.
        nix.extraOptions = ''
          !include /run/agenix/nix-access-tokens
        '';

        age.secrets = {
          openai-api-key = {
            file = ../../secrets/openai-api-key.age;
            owner = "soft";
          };
          gemini-api-key = {
            file = ../../secrets/gemini-api-key.age;
            owner = "soft";
          };
          # A nix.conf fragment rather than a bare token: flake inputs are
          # fetched client-side, so `soft` must read it, and nix.conf itself is
          # world-readable.
          nix-access-tokens = {
            file = ../../secrets/nix-access-tokens.age;
            owner = "soft";
          };
          z-ai-auth-token = {
            file = ../../secrets/z-ai-auth-token.age;
            owner = "soft";
          };
          # Home Assistant long-lived access token, used by Claude Code to
          # query sensor data and call services over the LAN (http://tower:8123).
          hass-token = {
            file = ../../secrets/hass-token.age;
            owner = "soft";
          };
          # Google Health API OAuth client credentials (the client secret JSON
          # downloaded from Google Cloud), used by Claude Code to read Fitbit Air
          # / health data. See the `google-health` skill (claude-code-wrapped
          # config) for the access recipe.
          google-health-oauth-client = {
            file = ../../secrets/google-health-oauth-client.age;
            owner = "soft";
          };
        };

        fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

        programs.direnv = {
          enable = true;
          settings.global.hide_env_diff = true;
        };
      };

    darwinModules.workstation = nixosModules.workstation;
  };
}

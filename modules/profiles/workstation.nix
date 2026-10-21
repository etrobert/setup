_: {
  flake = rec {
    nixosModules.workstation =
      {
        self,
        config,
        pkgs,
        ...
      }:
      {
        # Workstations have neovim-wrapped anyway, so `git sci` costs them nothing.
        wrappers.git.genCommitMsg = true;

        allowedUnfreePackages = [
          "claude-code"
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

            customPackages = with self.packages.${system}; [
              aichat-wrapped
              claude-code-wrapped
              alacritty-wrapped
              neovim-wrapped
              vscode-wrapped
              gen-commit-msg
              git-find-commit
              agents
              claude-new
              hass-cli-wrapped
              pm
              pdfshrink
              nixplatforms
              batr
              printline
              add-asset
              ils
              jqp-wrapped
            ];

            externalPackages = with pkgs; [
              act
              ast-grep

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
              jnv # jq TUI with filter completion, which jqp lacks
              libnotify
              nodejs

              # Notion ships no official Linux client; notion-electron is the
              # community Electron wrapper around the web app.
              (if stdenv.hostPlatform.isDarwin then notion-app else notion-electron)

              opencode
              pnpm
              python3
              shellcheck
              signal-desktop
              slack
              sops
              sox # Voice for claude
              spotify
              ssh-to-age
              telegram-desktop
              timg
              unzip
              yt-dlp
            ];
          in
          customPackages ++ externalPackages;

        # 30 github: inputs against an anonymous 60/hour-per-IP limit, shared by
        # every machine behind the same WAN address, is one `nix flake update`
        # away from exhaustion. `!include` is the tolerant form: nix skips it
        # when sops-nix has not rendered it yet, rather than failing to start.
        nix.extraOptions = ''
          !include ${config.sops.templates.nix-access-tokens.path}
        '';

        # Flake inputs are fetched client-side, so `soft` must read it, and
        # nix.conf itself is world-readable.
        sops.templates.nix-access-tokens = {
          content = "access-tokens = github.com=${config.sops.placeholder.nix-github-token}\n";
          owner = "soft";
        };

        sops.secrets = {
          openai-api-key = {
            sopsFile = ../../secrets/workstations.yaml;
            owner = "soft";
          };
          gemini-api-key = {
            sopsFile = ../../secrets/workstations.yaml;
            owner = "soft";
          };
          nix-github-token.sopsFile = ../../secrets/workstations.yaml;
          # Home Assistant long-lived access token, used by Claude Code to
          # query sensor data and call services over the LAN (http://tower:8123).
          hass-token = {
            sopsFile = ../../secrets/workstations.yaml;
            owner = "soft";
          };
          # Google Health API OAuth client credentials (the client secret JSON
          # downloaded from Google Cloud), used by Claude Code to read Fitbit Air
          # / health data. See the `google-health` skill (claude-code-wrapped
          # config) for the access recipe.
          google-health-oauth-client = {
            sopsFile = ../../secrets/workstations.yaml;
            owner = "soft";
          };
        };

        fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

        programs.direnv = {
          enable = true;
          settings = {
            global.hide_env_diff = true;
            # Trusted upfront so fresh lafraise worktrees skip `direnv allow`.
            whitelist.prefix = [ "~/work/lafraise" ];
          };
        };
      };

    darwinModules.workstation = nixosModules.workstation;
  };
}

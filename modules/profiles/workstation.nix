_: {
  flake = rec {
    nixosModules.workstation =
      {
        self,
        agenix,
        lib,
        pkgs,
        ...
      }:
      {
        # Workstations have neovim-wrapped anyway, so `git sci` costs them nothing.
        wrappers.git.genCommitMsg = true;

        allowedUnfreePackages = [
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

            # nixpkgs ships a stale node_modules hash, fixed by NixOS/nixpkgs@c399e1b7fb.
            opencode = pkgs.opencode.overrideAttrs (old: {
              node_modules =
                assert lib.assertMsg
                  (old.node_modules.outputHash == "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc=")
                  "nixpkgs fixed opencode's node_modules hash; drop the override in modules/profiles/workstation.nix";
                old.node_modules.overrideAttrs {
                  outputHash =
                    if pkgs.stdenv.hostPlatform.isLinux then
                      "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA="
                    else
                      "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc=";
                };
            });

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
          inputPackages ++ customPackages ++ externalPackages ++ [ opencode ];

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

{ self, inputs, ... }:
{
  perSystem =
    {
      self',
      pkgs,
      lib,
      inputs',
      ...
    }:
    let
      # Latest Claude Code, ahead of nixpkgs' cadence (see flake.nix input).
      # Minimal variant: the full one bundles gh, which our wrapper does not
      # need (it manages PATH and ships its own gitconfig-bot).
      claude-code = inputs'.nix-claude-code.packages.claude-minimal;

      # Our fork (see flake.nix); newer than nixpkgs, which needs Enter for -e.
      aichat = inputs'.aichat.packages.default;
      ntfy-wrapped = pkgs.callPackage ./ntfy-wrapped { };
      hass-cli-wrapped = pkgs.callPackage ./hass-cli-wrapped { };
      git-wrapped = pkgs.callPackage ./git-wrapped { inherit self'; };
    in
    {
      packages = {
        aichat-wrapped = pkgs.callPackage ./aichat-wrapped {
          inherit aichat;
          inherit (self'.packages) claude-code-wrapped;
        };
        atuin-wrapped = pkgs.callPackage ./atuin-wrapped { };
        fzf-wrapped = pkgs.callPackage ./fzf-wrapped { };
        bash-wrapped = pkgs.callPackage ./bash-wrapped {
          inherit inputs';
          inherit (self'.packages) fzf-wrapped;
        };
        zsh-wrapped = pkgs.callPackage ./zsh-wrapped {
          inherit inputs';
          inherit (self'.packages) fzf-wrapped atuin-wrapped;
        };
        neovim-wrapped = pkgs.callPackage ./neovim-wrapped { inherit self'; };
        vim-wrapped = pkgs.callPackage ./vim-wrapped { };
        tmux-wrapped = pkgs.callPackage ./tmux-wrapped { };
        alacritty-wrapped = pkgs.callPackage ./alacritty-wrapped { };
        vscode-wrapped = pkgs.callPackage ./vscode-wrapped { };
        claude-code-wrapped = pkgs.callPackage ./claude-code-wrapped {
          inherit
            claude-code
            git-wrapped
            ntfy-wrapped
            hass-cli-wrapped
            ;
          inherit (inputs) figma-mcp-plugin;
        };
        claude-code-wrapped-glm = pkgs.callPackage ./claude-code-wrapped {
          inherit
            claude-code
            git-wrapped
            ntfy-wrapped
            hass-cli-wrapped
            ;
          inherit (inputs) figma-mcp-plugin;
          extraEnv = {
            ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
            API_TIMEOUT_MS = "3000000";
            ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-4.5-air";
            ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-5.1";
            ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-5.1";
          };
          readTokenFromAgenix = true;
          binName = "claude-glm";
        };
        # TTS backends for `speak` (stdin -> audio). Selected at runtime via
        # $SPEAK_TTS; each is runnable standalone, e.g. `echo hi | nix run .#tts-say`.
        tts-say = pkgs.callPackage ./claude-code-wrapped/tts-say.nix { };
        tts-piper = pkgs.callPackage ./claude-code-wrapped/tts-piper.nix { };
        claude-code-wrapped-copilot = pkgs.callPackage ./claude-code-wrapped {
          inherit
            claude-code
            git-wrapped
            ntfy-wrapped
            hass-cli-wrapped
            ;
          inherit (inputs) figma-mcp-plugin;
          extraEnv = {
            ANTHROPIC_BASE_URL = "http://localhost:4141";
            ANTHROPIC_AUTH_TOKEN = "dummy"; # proxy authenticates via GitHub itself
            API_TIMEOUT_MS = "3000000";
            ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4.5";
            ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4.6";
            # Opus is unavailable on Copilot Pro; degrade to Sonnet rather than error.
            ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-sonnet-4.6";
          };
          binName = "claude-copilot";
        };
        batr = pkgs.callPackage ./batr.nix { };
        birthdays = pkgs.callPackage ./birthdays { };
        gen-commit-msg = pkgs.callPackage ./gen-commit-msg { inherit self'; };
        git-find-commit = pkgs.callPackage ./git-find-commit {
          inherit (self'.packages) fzf-wrapped;
        };
        git-worktree-add = pkgs.callPackage ./git-worktree-add { inherit self'; };
        agents = pkgs.callPackage ./agents { inherit self'; };
        flake-input-table = pkgs.callPackage ./flake-input-table { };
        inherit ntfy-wrapped hass-cli-wrapped git-wrapped;
        send-file = pkgs.callPackage ./send-file { inherit ntfy-wrapped; };
        pm = pkgs.callPackage ./pm { };
        pdfshrink = pkgs.callPackage ./pdfshrink { };
        nixplatforms = pkgs.callPackage ./nixplatforms.nix { };
        printline = pkgs.callPackage ./printline.nix { };
        creme = pkgs.callPackage ./creme { };
        check-bt-profile = pkgs.callPackage ./check-bt-profile { };
        tmux-sessionizer = pkgs.callPackage ./tmux-sessionizer { inherit self' inputs'; };
        get-weather = pkgs.callPackage ./get-weather { };
        ils = pkgs.callPackage ./ils { };
        add-asset = pkgs.callPackage ./add-asset { };
        setuid-sudo = pkgs.callPackage ./setuid-sudo { };
        switch = pkgs.callPackage ./switch.nix { inherit self'; };
        deadnix-errfmt = pkgs.callPackage ./deadnix-errfmt { };
        firefox-wrapped = pkgs.callPackage ./firefox-wrapped { inherit self; };
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        flush-dns = pkgs.callPackage ./flush-dns { };
        resize-window = pkgs.callPackage ./resize-window { };
        finder = pkgs.callPackage ./finder { };
        ghostty-wrapped = pkgs.callPackage ./ghostty-wrapped {
          ghostty = pkgs.ghostty-bin;
        };
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        zen-browser-wrapped = pkgs.callPackage ./zen-browser-wrapped { inherit self inputs'; };
        waybar-wrapped = pkgs.callPackage ./waybar-wrapped { inherit self'; };
        waybar-wrapped-dev = pkgs.callPackage ./waybar-wrapped {
          inherit self';
          dev = true;
        };
        noctalia-wrapped = pkgs.callPackage ./noctalia-wrapped {
          official-plugins = inputs.noctalia-official-plugins;
          community-plugins = inputs.noctalia-community-plugins;
        };
        niri-wrapped = pkgs.callPackage ./niri-wrapped { inherit self'; };
        niri-wrapped-dev = pkgs.callPackage ./niri-wrapped {
          inherit self';
          dev = true;
        };
        audio-output-switcher = pkgs.callPackage ./audio-output-switcher {
          inherit (self'.packages) fzf-wrapped;
        };
        scale-floating-window = pkgs.callPackage ./scale-floating-window { };
        open-url = pkgs.callPackage ./open-url { inherit self'; };
        lock-suspend = pkgs.callPackage ./lock-suspend.nix { };
        linear = pkgs.callPackage ./linear { };
        ghostty-wrapped = pkgs.callPackage ./ghostty-wrapped {
          inherit (pkgs) ghostty;
        };
      };
    };
}

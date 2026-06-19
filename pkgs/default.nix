{ self, ... }:
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
      wrapPackage = pkgs.callPackage ./lib/wrap-package.nix { };
      ntfy-wrapped = pkgs.callPackage ./ntfy-wrapped { inherit wrapPackage; };
      hass-cli-wrapped = pkgs.callPackage ./hass-cli-wrapped { };
    in
    {
      packages = {
        bash-wrapped = pkgs.callPackage ./bash-wrapped { inherit inputs'; };
        git-wrapped = pkgs.callPackage ./git-wrapped { inherit self'; };
        zsh-wrapped = pkgs.callPackage ./zsh-wrapped { inherit inputs'; };
        neovim-wrapped = pkgs.callPackage ./neovim-wrapped { inherit self'; };
        vim-wrapped = pkgs.callPackage ./vim-wrapped { inherit wrapPackage; };
        tmux-wrapped = pkgs.callPackage ./tmux-wrapped { inherit wrapPackage; };
        alacritty-wrapped = pkgs.callPackage ./alacritty-wrapped { inherit wrapPackage; };
        vscode-wrapped = pkgs.callPackage ./vscode-wrapped { };
        claude-code-wrapped = pkgs.callPackage ./claude-code-wrapped {
          inherit claude-code ntfy-wrapped hass-cli-wrapped;
        };
        claude-code-wrapped-glm = pkgs.callPackage ./claude-code-wrapped {
          inherit claude-code ntfy-wrapped hass-cli-wrapped;
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
        copilot-api = pkgs.callPackage ./copilot-api { };
        claude-code-wrapped-copilot = pkgs.callPackage ./claude-code-wrapped {
          inherit claude-code ntfy-wrapped hass-cli-wrapped;
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
        claude-restart-daemon = pkgs.callPackage ./claude-restart-daemon { };
        batr = pkgs.callPackage ./batr.nix { };
        birthdays = pkgs.callPackage ./birthdays { };
        gen-commit-msg = pkgs.callPackage ./gen-commit-msg { inherit self'; };
        git-find-commit = pkgs.callPackage ./git-find-commit { };
        inherit ntfy-wrapped hass-cli-wrapped;
        pm = pkgs.callPackage ./pm { };
        pdfshrink = pkgs.callPackage ./pdfshrink { };
        nixplatforms = pkgs.callPackage ./nixplatforms.nix { };
        printline = pkgs.callPackage ./printline.nix { };
        creme = pkgs.callPackage ./creme { };
        check-bt-profile = pkgs.callPackage ./check-bt-profile { };
        tmux-sessionizer = pkgs.callPackage ./tmux-sessionizer { inherit self'; };
        get-weather = pkgs.callPackage ./get-weather { };
        ils = pkgs.callPackage ./ils { };
        add-asset = pkgs.callPackage ./add-asset { };
        switch = pkgs.callPackage ./switch.nix { };
        deadnix-errfmt = pkgs.callPackage ./deadnix-errfmt { };
        firefox-wrapped = pkgs.callPackage ./firefox-wrapped { inherit self; };
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        flush-dns = pkgs.callPackage ./flush-dns { };
        resize-window = pkgs.callPackage ./resize-window { };
        finder = pkgs.callPackage ./finder { };
        ghostty-wrapped = pkgs.callPackage ./ghostty-wrapped { ghostty = pkgs.ghostty-bin; };
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        zen-browser-wrapped = pkgs.callPackage ./zen-browser-wrapped { inherit self inputs'; };
        toggle-cpu-governor = pkgs.callPackage ./toggle-cpu-governor { };
        waybar-wrapped = pkgs.callPackage ./waybar-wrapped { inherit self' wrapPackage; };
        waybar-wrapped-dev = pkgs.callPackage ./waybar-wrapped {
          inherit self' wrapPackage;
          dev = true;
        };
        fuzzel-wrapped = pkgs.callPackage ./fuzzel-wrapped { inherit wrapPackage; };
        niri-wrapped = pkgs.callPackage ./niri-wrapped { inherit self'; };
        niri-wrapped-dev = pkgs.callPackage ./niri-wrapped {
          inherit self';
          dev = true;
        };
        darkman-wrapped = pkgs.callPackage ./darkman-wrapped { };
        mako-wrapped = pkgs.callPackage ./mako-wrapped { inherit wrapPackage; };
        audio-output-switcher = pkgs.callPackage ./audio-output-switcher { };
        brightness-control = pkgs.callPackage ./brightness-control { };
        ddcci-register = pkgs.callPackage ./ddcci-register { };
        scale-floating-window = pkgs.callPackage ./scale-floating-window { };
        open-url = pkgs.callPackage ./open-url { inherit self'; };
        volume-control = pkgs.callPackage ./volume-control { };
        lock-suspend = pkgs.callPackage ./lock-suspend.nix { };
        album-art-wallpaper = pkgs.callPackage ./album-art-wallpaper.nix { };
        awww-restore-on-hotplug = pkgs.callPackage ./awww-restore-on-hotplug.nix { };
        ghostty-wrapped = pkgs.callPackage ./ghostty-wrapped { inherit (pkgs) ghostty; };
      };
    };
}

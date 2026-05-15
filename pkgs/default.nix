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
    {
      packages = {
        bash-wrapped = pkgs.callPackage ./bash-wrapped { inherit inputs'; };
        git-wrapped = pkgs.callPackage ./git-wrapped { inherit self'; };
        zsh-wrapped = pkgs.callPackage ./zsh-wrapped { inherit inputs'; };
        neovim-wrapped = pkgs.callPackage ./neovim-wrapped { inherit self'; };
        vim-wrapped = pkgs.callPackage ./vim-wrapped { };
        tmux-wrapped = pkgs.callPackage ./tmux-wrapped { };
        alacritty-wrapped = pkgs.callPackage ./alacritty-wrapped { };
        vscode-wrapped = pkgs.callPackage ./vscode-wrapped { };
        batr = pkgs.callPackage ./batr.nix { };
        birthdays = pkgs.callPackage ./birthdays { };
        gen-commit-msg = pkgs.callPackage ./gen-commit-msg { inherit self'; };
        git-find-commit = pkgs.callPackage ./git-find-commit { };
        pm = pkgs.callPackage ./pm { };
        pdfshrink = pkgs.callPackage ./pdfshrink { };
        nixplatforms = pkgs.callPackage ./nixplatforms.nix { };
        printline = pkgs.callPackage ./printline.nix { };
        creme = pkgs.callPackage ./creme { };
        check-bt-profile = pkgs.callPackage ./check-bt-profile { };
        tmux-sessionizer = pkgs.callPackage ./tmux-sessionizer { inherit self'; };
        get-weather = pkgs.callPackage ./get-weather { };
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
        waybar-wrapped = pkgs.callPackage ./waybar-wrapped { inherit self'; };
        waybar-wrapped-dev = pkgs.callPackage ./waybar-wrapped {
          inherit self';
          dev = true;
        };
        niri-wrapped = pkgs.callPackage ./niri-wrapped { inherit self'; };
        niri-wrapped-dev = pkgs.callPackage ./niri-wrapped {
          inherit self';
          dev = true;
        };
        darkman-wrapped = pkgs.callPackage ./darkman-wrapped { };
        hyprpaper-wrapped = pkgs.callPackage ./hyprpaper-wrapped { };
        mako-wrapped = pkgs.callPackage ./mako-wrapped { };
        audio-output-switcher = pkgs.callPackage ./audio-output-switcher { };
        brightness-control = pkgs.callPackage ./brightness-control { };
        scale-floating-window = pkgs.callPackage ./scale-floating-window { };
        open-url = pkgs.callPackage ./open-url { inherit self'; };
        volume-control = pkgs.callPackage ./volume-control { };
        lock-suspend = pkgs.callPackage ./lock-suspend.nix { };
        album-art-wallpaper = pkgs.callPackage ./album-art-wallpaper.nix { };
        ghostty-wrapped = pkgs.callPackage ./ghostty-wrapped { inherit (pkgs) ghostty; };
      };
    };
}

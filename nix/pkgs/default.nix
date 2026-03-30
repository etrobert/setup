_: {
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    {
      packages = {
        git-wrapped = pkgs.callPackage ./git-wrapped { };
        neovim-wrapped = pkgs.callPackage ./neovim-wrapped.nix { inherit self'; };
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
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        toggle-cpu-governor = pkgs.callPackage ./toggle-cpu-governor { };
        waybar-wrapped = pkgs.callPackage ./waybar-wrapped { inherit self'; };
        mako-wrapped = pkgs.callPackage ./mako-wrapped { };
        brightness-control = pkgs.callPackage ./brightness-control { };
        volume-control = pkgs.callPackage ./volume-control { };
        lock-suspend = pkgs.callPackage ./lock-suspend.nix { };
        album-art-wallpaper = pkgs.callPackage ./album-art-wallpaper.nix { };
      };
    };
}

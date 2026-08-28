{
  self,
  lib,
  ...
}:
{
  # A package that has plumbing of its own owns it, in a flake-module.nix
  # beside its derivation. The rest are listed below until they follow.
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}/flake-module.nix") (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (./. + "/${name}/flake-module.nix")
    ) (builtins.readDir ./.)
  );

  perSystem =
    {
      self',
      pkgs,
      lib,
      inputs',
      ...
    }:
    let
      # Our fork (see flake.nix); newer than nixpkgs, which needs Enter for -e.
      aichat = inputs'.aichat.packages.default;
      ntfy-wrapped = pkgs.callPackage ./ntfy-wrapped { };
      hass-cli-wrapped = pkgs.callPackage ./hass-cli-wrapped { };
    in
    {
      # Each package says which platforms it supports; anything that does not
      # support this one is dropped rather than named here.
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
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
        tmux-wrapped = pkgs.callPackage ./tmux-wrapped { };
        alacritty-wrapped = pkgs.callPackage ./alacritty-wrapped { };
        vscode-wrapped = pkgs.callPackage ./vscode-wrapped { };
        batr = pkgs.callPackage ./batr.nix { };
        birthdays = pkgs.callPackage ./birthdays { };
        gen-commit-msg = pkgs.callPackage ./gen-commit-msg { inherit self'; };
        git-find-commit = pkgs.callPackage ./git-find-commit {
          inherit (self'.packages) fzf-wrapped;
        };
        git-worktree-add = pkgs.callPackage ./git-worktree-add { inherit self'; };
        agents = pkgs.callPackage ./agents { inherit self'; };
        flake-input-table = pkgs.callPackage ./flake-input-table { };
        inherit ntfy-wrapped hass-cli-wrapped;
        send-file = pkgs.callPackage ./send-file { inherit ntfy-wrapped; };
        pm = pkgs.callPackage ./pm { };
        pdfshrink = pkgs.callPackage ./pdfshrink { };
        nixplatforms = pkgs.callPackage ./nixplatforms.nix { };
        printline = pkgs.callPackage ./printline.nix { };
        creme = pkgs.callPackage ./creme { };
        check-bt-profile = pkgs.callPackage ./check-bt-profile { };
        tmux-sessionizer = pkgs.callPackage ./tmux-sessionizer { inherit self' inputs'; };
        ils = pkgs.callPackage ./ils { };
        add-asset = pkgs.callPackage ./add-asset { };
        setuid-sudo = pkgs.callPackage ./setuid-sudo { };
        switch = pkgs.callPackage ./switch.nix { inherit self'; };
        deadnix-errfmt = pkgs.callPackage ./deadnix-errfmt { };
        firefox-wrapped = pkgs.callPackage ./firefox-wrapped { inherit self; };

        flush-dns = pkgs.callPackage ./flush-dns { };
        resize-window = pkgs.callPackage ./resize-window { };
        finder = pkgs.callPackage ./finder { };

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
        pimsync-wrapped = pkgs.callPackage ./pimsync-wrapped { };
      };
    };
}

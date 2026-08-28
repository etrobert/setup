{
  self,
  lib,
  ...
}:
let
  entries = builtins.readDir ./.;

  # A package with plumbing of its own owns it, in a flake-module.nix beside its
  # derivation.
  ownsWiring = name: builtins.pathExists (./. + "/${name}/flake-module.nix");

  # Everything else is a directory holding a default.nix, or a lone .nix file.
  discoverable = lib.filterAttrs (
    name: type:
    if type == "directory" then
      !ownsWiring name && builtins.pathExists (./. + "/${name}/default.nix")
    else
      name != "default.nix" && lib.hasSuffix ".nix" name
  ) entries;

  packageName = name: lib.removeSuffix ".nix" name;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}/flake-module.nix") (
    lib.filterAttrs (name: type: type == "directory" && ownsWiring name) entries
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
      # Packages callPackage cannot assemble on its own, because they take an
      # argument that is not a nixpkgs attribute. Everything else is discovered.
      wired = {
        aichat-wrapped = pkgs.callPackage ./aichat-wrapped {
          # Our fork (see flake.nix); newer than nixpkgs, which needs Enter for -e.
          aichat = inputs'.aichat.packages.default;
          inherit (self'.packages) claude-code-wrapped;
        };
        bash-wrapped = pkgs.callPackage ./bash-wrapped {
          inherit inputs';
          inherit (self'.packages) fzf-wrapped;
        };
        zsh-wrapped = pkgs.callPackage ./zsh-wrapped {
          inherit inputs';
          inherit (self'.packages) fzf-wrapped atuin-wrapped;
        };
        neovim-wrapped = pkgs.callPackage ./neovim-wrapped { inherit self'; };
        gen-commit-msg = pkgs.callPackage ./gen-commit-msg { inherit self'; };
        git-find-commit = pkgs.callPackage ./git-find-commit {
          inherit (self'.packages) fzf-wrapped;
        };
        git-worktree-add = pkgs.callPackage ./git-worktree-add { inherit self'; };
        agents = pkgs.callPackage ./agents { inherit self'; };
        send-file = pkgs.callPackage ./send-file { inherit (self'.packages) ntfy-wrapped; };
        tmux-sessionizer = pkgs.callPackage ./tmux-sessionizer { inherit self' inputs'; };
        switch = pkgs.callPackage ./switch.nix { inherit self'; };
        firefox-wrapped = pkgs.callPackage ./firefox-wrapped { inherit self; };
        niri-wrapped = pkgs.callPackage ./niri-wrapped { inherit self'; };
        niri-wrapped-dev = pkgs.callPackage ./niri-wrapped {
          inherit self';
          dev = true;
        };
        audio-output-switcher = pkgs.callPackage ./audio-output-switcher {
          inherit (self'.packages) fzf-wrapped;
        };
        open-url = pkgs.callPackage ./open-url { inherit self'; };
      };

      discovered = lib.mapAttrs' (
        name: _: lib.nameValuePair (packageName name) (pkgs.callPackage (./. + "/${name}") { })
      ) (lib.filterAttrs (name: _: !wired ? ${packageName name}) discoverable);
    in
    {
      # Each package says which platforms it supports; anything that does not
      # support this one is dropped rather than named here.
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) (discovered // wired);
    };
}

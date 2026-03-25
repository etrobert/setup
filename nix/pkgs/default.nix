{ pkgs }:
{
  neovim-wrapped = pkgs.callPackage ./neovim-wrapped.nix { };
  batr = pkgs.callPackage ./batr.nix { };
  birthdays = pkgs.callPackage ./birthdays { };
  gen-commit-msg = pkgs.callPackage ./gen-commit-msg.nix { };
  git-find-commit = pkgs.callPackage ./git-find-commit.nix { };
  pm = pkgs.callPackage ./pm { };
  pdfshrink = pkgs.callPackage ./pdfshrink { };
  nixplatforms = pkgs.callPackage ./nixplatforms.nix { };
  printline = pkgs.callPackage ./printline.nix { };
  toggle-cpu-governor = pkgs.callPackage ./toggle-cpu-governor { };
  waybar-wrapped = pkgs.callPackage ./waybar-wrapped.nix { };
  brightness-control = pkgs.callPackage ./brightness-control { };
  volume-control = pkgs.callPackage ./volume-control { };
  creme = pkgs.callPackage ./creme { };
  lock-suspend = pkgs.callPackage ./lock-suspend.nix { };
  check-bt-profile = pkgs.callPackage ./check-bt-profile { };
  tmux-sessionizer = pkgs.callPackage ./tmux-sessionizer { };
}

{ pkgs }:
{
  neovim-wrapped = import ./neovim-wrapped.nix { inherit pkgs; };
  batr = import ./batr.nix { inherit pkgs; };
  birthdays = import ./birthdays { inherit pkgs; };
  gen-commit-msg = import ./gen-commit-msg.nix { inherit pkgs; };
  git-find-commit = import ./git-find-commit.nix { inherit pkgs; };
  pm = import ./pm { inherit pkgs; };
  pdfshrink = import ./pdfshrink.nix { inherit pkgs; };
  nixplatforms = import ./nixplatforms.nix { inherit pkgs; };
  printline = import ./printline.nix { inherit pkgs; };
}

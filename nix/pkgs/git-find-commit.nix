{ pkgs }:
pkgs.writeShellApplication {
  name = "git-find-commit";
  runtimeInputs = with pkgs; [
    coreutils
    git
    fzf
    findutils # xargs
  ];
  inheritPath = false;
  text = builtins.readFile ../../git/.local/bin/git-find-commit;
}

{
  writeShellApplication,
  coreutils,
  git,
  fzf-wrapped,
  findutils,
}:
writeShellApplication {
  name = "git-find-commit";
  runtimeInputs = [
    coreutils
    git
    fzf-wrapped
    findutils # xargs
  ];
  inheritPath = false;
  text = builtins.readFile ./git-find-commit.sh;
}

{
  writeShellApplication,
  coreutils,
  git,
  fzf,
  findutils,
}:
writeShellApplication {
  name = "git-find-commit";
  runtimeInputs = [
    coreutils
    git
    fzf
    findutils # xargs
  ];
  inheritPath = false;
  text = builtins.readFile ./git-find-commit.sh;
}

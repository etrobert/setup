{
  self',
  writeShellApplication,
  coreutils,
  git,
}:
writeShellApplication {
  name = "git-worktree-add";
  inheritPath = false;

  runtimeInputs = [
    coreutils
    git
    self'.packages.tmux-sessionizer
  ];

  text = builtins.readFile ./git-worktree-add.sh;
}

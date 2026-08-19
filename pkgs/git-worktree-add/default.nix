{
  self',
  writeShellApplication,
  coreutils,
  git,
}:
writeShellApplication {
  name = "git-worktree-add";

  runtimeInputs = [
    coreutils
    git
    self'.packages.tmux-sessionizer
  ];

  text = builtins.readFile ./git-worktree-add.sh;
}

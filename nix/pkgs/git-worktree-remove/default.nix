{
  writeShellApplication,
  coreutils,
  git,
  tmux,
}:
writeShellApplication {
  name = "git-worktree-remove";
  runtimeInputs = [
    coreutils
    git
    tmux
  ];
  inheritPath = false;
  text = builtins.readFile ./git-worktree-remove.sh;
}

{
  tmux-sessionizer,
  writeShellApplication,
  coreutils,
  git,
}:
writeShellApplication {
  name = "git-worktree-add";
  # Hands its PATH to the tmux session tmux-sessionizer creates; clearing it
  # leaves that session without nvim, zsh or anything else on PATH.
  inheritPath = true;

  runtimeInputs = [
    coreutils
    git
    tmux-sessionizer
  ];

  text = builtins.readFile ./git-worktree-add.sh;
}

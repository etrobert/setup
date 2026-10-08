{
  coreutils,
  git,
  jq,
  writeShellApplication,
}:
writeShellApplication {
  name = "claude-trust-worktree";
  runtimeInputs = [
    coreutils
    git
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./claude-trust-worktree.sh;
}

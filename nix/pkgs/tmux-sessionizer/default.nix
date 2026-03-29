{
  writeShellApplication,
  coreutils,
  gnused,
  tmux,
  fzf,
  findutils,
}:
writeShellApplication {
  name = "tmux-sessionizer";
  runtimeInputs = [
    coreutils
    gnused
    tmux
    fzf
    findutils
  ];
  inheritPath = true;
  text = builtins.readFile ./tmux-sessionizer.sh;
}

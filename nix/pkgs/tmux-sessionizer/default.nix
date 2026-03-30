{
  self',
  writeShellApplication,
  coreutils,
  gnused,
  fzf,
  findutils,
}:
writeShellApplication {
  name = "tmux-sessionizer";
  runtimeInputs = [
    coreutils
    gnused
    self'.packages.tmux-wrapped
    fzf
    findutils
  ];
  inheritPath = true;
  text = builtins.readFile ./tmux-sessionizer.sh;
}

{
  self',
  writeShellApplication,
  coreutils,
  curl,
  git,
  gnused,
  jq,
}:
writeShellApplication {
  name = "gen-commit-msg";
  runtimeInputs = [
    coreutils
    curl
    (self'.packages.neovim-wrapped.override { with-git = false; }) # for editing the commit
    git
    gnused
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ./gen-commit-msg.sh;
}

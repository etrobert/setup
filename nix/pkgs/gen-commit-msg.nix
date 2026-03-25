{
  writeShellApplication,
  coreutils,
  curl,
  neovim,
  git,
  gnused,
  jq,
}:
writeShellApplication {
  name = "gen-commit-msg";
  runtimeInputs = [
    coreutils
    curl
    neovim # for editing the commit
    git
    gnused
    jq
  ];
  inheritPath = false;
  text = builtins.readFile ../../git/.local/bin/gen-commit-msg;
}

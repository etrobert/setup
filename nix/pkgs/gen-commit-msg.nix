{ pkgs }:
pkgs.writeShellApplication {
  name = "gen-commit-msg";
  runtimeInputs = with pkgs; [
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

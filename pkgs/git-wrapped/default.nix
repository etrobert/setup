{
  pkgs,
  self',
  lib,
  userConfig ? ./gitconfig-user,
}:
# TODO: --set PATH
let
  deps = with pkgs; [
    # TODO: Fix this
    # Removed so that neovim-wrapped is not included on the pi
    # self'.packages.gen-commit-msg
    difftastic
    fzf
  ];

  git-worktree-add = pkgs.writeShellApplication {
    name = "git-worktree-add";
    runtimeInputs = with pkgs; [
      coreutils
      git
      self'.packages.tmux-sessionizer
    ];
    text = builtins.readFile ./git-worktree-add.sh;
  };

  git-worktree-remove = pkgs.writeShellApplication {
    name = "git-worktree-remove";
    runtimeInputs = with pkgs; [
      coreutils
      git
      tmux
    ];
    text = builtins.readFile ./git-worktree-remove.sh;
  };
  systemConfig = pkgs.concatText "gitconfig-system" [
    ./gitconfig-system
    (pkgs.writeText "gitconfig-system-excludes" /* gitconfig */ ''
      [core]
        excludesFile = ${./gitignore-global}
    '')
  ];
in
pkgs.symlinkJoin {
  name = "git-wrapped";
  nativeBuildInputs = with pkgs; [ makeWrapper ];
  paths =
    with pkgs;
    [ git ]
    ++ [
      git-worktree-add
      git-worktree-remove
    ];
  meta.mainProgram = "git";
  postBuild = ''
    wrapProgram $out/bin/git \
      --set GIT_CONFIG_SYSTEM ${systemConfig} \
      --set GIT_CONFIG_GLOBAL ${userConfig} \
      --prefix PATH : ${lib.makeBinPath deps}
  '';
}

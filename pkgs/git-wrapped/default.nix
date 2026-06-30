{
  pkgs,
  self',
  wrapPackage,
  userConfig ? ./gitconfig-user,
}:
# TODO: restrict PATH to explicit inputs (inheritPath = false) rather than
# inheriting the ambient PATH — see discussion on #295.
let
  deps = with pkgs; [
    # TODO: Fix this
    # Removed so that neovim-wrapped is not included on the pi
    # self'.packages.gen-commit-msg
    difftastic
    fzf

    # Tools the shell aliases in gitconfig-system call out to. Without these the
    # aliases break when nothing on the ambient PATH provides them (e.g. under a
    # bare `nix run`).
    bat # ushow
    coreutils # sort, cut (alias, falias, fw)
    findutils # xargs (dbranch, ushow, falias)
    gnugrep # grep (dbranch, alias)
    gnused # sed (sco, alias)
    util-linux # column (alias)
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
wrapPackage {
  package = pkgs.git;
  extraPaths = [
    git-worktree-add
    git-worktree-remove
  ];
  env = {
    GIT_CONFIG_SYSTEM = "${systemConfig}";
    GIT_CONFIG_GLOBAL = "${userConfig}";
  };
  runtimeInputs = deps;
  inheritPath = true;
}

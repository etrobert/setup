{
  pkgs,
  self',
  wrapPackage,
  userConfig ? ./gitconfig-user,
  # Host-specific tools git shells out to that we don't want in every closure
  # (notably the editor / gen-commit-msg, which pull neovim-wrapped — kept off
  # the pi). Workstations inject these via modules/workstation.nix.
  extraRuntimeInputs ? [ ],
}:
let
  # git runs with inheritPath = false, so it sees a controlled PATH rather than
  # the ambient one. Everything git shells out to during normal operation and
  # for the aliases baked into gitconfig-system must be enumerated here.
  deps =
    (with pkgs; [
      difftastic # `ds`/`dft`/`dlog`/`dshow`/`slist` aliases (diff.external=difft)
      fzf # `sco`/`falias`/`fw` aliases
      gnused # `sco`/`alias` aliases
      gnugrep # `dbranch`/`alias` aliases
      findutils # xargs in `dbranch`/`ushow`/`falias`
      util-linux # column in `alias`
      coreutils # sort/cut/column pipelines in `alias`/`falias`/`fw`
      bat # `ushow` alias
      less # default pager
      openssh # push/fetch over SSH
    ])
    ++ extraRuntimeInputs;

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
  inheritPath = false;
}

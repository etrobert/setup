{
  pkgs,
  self',
  wrapPackage,
  userConfig ? ./gitconfig-user,
}:
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

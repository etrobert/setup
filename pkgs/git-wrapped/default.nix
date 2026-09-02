{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages =
        let
          makeGit = lib.makeOverridable (
            {
              userConfig ? ./gitconfig-user,
              # gen-commit-msg pulls neovim-wrapped in, a ~3.7 GiB closure the pi
              # must not carry, so hosts that want `git sci` opt in. Off by
              # default: every in-repo consumer of `git-wrapped` inherits it.
              genCommitMsg ? false,
            }:
            let
              deps =
                with pkgs;
                [
                  difftastic
                  self'.packages.fzf-wrapped

                  # Tools the shell aliases in gitconfig-system call out to. Without these the
                  # aliases break when nothing on the ambient PATH provides them (e.g. under a
                  # bare `nix run`).
                  bat # ushow
                  coreutils # sort, cut (alias, falias, fw)
                  findutils # xargs (dbranch, ushow, falias)
                  gnugrep # grep (dbranch, alias)
                  gnused # sed (sco, alias)
                  util-linux # column (alias)
                ]
                ++ lib.optional genCommitMsg self'.packages.gen-commit-msg;

              git-worktree-remove = pkgs.writeShellApplication {
                name = "git-worktree-remove";
                inheritPath = false;

                runtimeInputs = with pkgs; [
                  coreutils
                  git
                  tmux
                ];

                text = builtins.readFile ./git-worktree-remove.sh;
              };

              git-project-clone = pkgs.writeShellApplication {
                name = "git-project-clone";
                inheritPath = false;

                runtimeInputs = with pkgs; [
                  coreutils
                  git
                  openssh # git fetch over ssh:// shells out to it
                ];

                text = builtins.readFile ./git-project-clone.sh;
              };

              systemConfig = pkgs.concatText "gitconfig-system" [
                ./gitconfig-system
                (pkgs.writeText "gitconfig-system-excludes" /* gitconfig */ ''
                  [core]
                    excludesFile = ${./gitignore-global}
                '')
              ];
            in
            pkgs.wrapPackage {
              package = pkgs.git;
              extraPaths = [
                git-project-clone
                git-worktree-remove
              ];
              env = {
                GIT_CONFIG_SYSTEM = "${systemConfig}";
                GIT_CONFIG_GLOBAL = "${userConfig}";
              };
              runtimeInputs = deps;
              # Must stay: git resolves core.editor (nvim) and the `sci`/`find` aliases'
              # helpers off the ambient PATH; deps deliberately omits them.
              inheritPath = true;
            }
          );
        in
        {
          git-wrapped = makeGit { };
          git-wrapped-full = makeGit { genCommitMsg = true; };
        };
    };

  # Defined once and exported to both classes, as modules/unfree.nix does:
  # flake-parts stamps a class on each, and git is imported by nixos-base and
  # by aaron.
  flake =
    let
      gitModule =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          inherit (self.packages.${system}) git-wrapped git-wrapped-full;
        in
        {
          options.wrappers.git = {
            genCommitMsg = lib.mkEnableOption "the `git sci` helper, which adds neovim-wrapped (~3.7 GiB) to git's closure";

            wrapper = lib.mkOption {
              type = lib.types.package;
              default = if config.wrappers.git.genCommitMsg then git-wrapped-full else git-wrapped;
            };
          };
        };
    in
    {
      nixosModules.git = gitModule;
      darwinModules.git = gitModule;
    };
}

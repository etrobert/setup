_: {
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.git-wrapped = lib.makeOverridable (
        {
          userConfig ? ./gitconfig-user,
        }:
        let
          deps = with pkgs; [
            # TODO: Fix this
            # Removed so that neovim-wrapped is not included on the pi
            # self'.packages.gen-commit-msg
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
          ];

          gitEnv = {
            GIT_CONFIG_SYSTEM = "${systemConfig}";
            GIT_CONFIG_GLOBAL = "${userConfig}";
          };

          # The scripts below ship inside git-wrapped, so they cannot depend on
          # it. They get the same config from a sibling wrapper instead.
          git-configured = pkgs.wrapPackage {
            package = pkgs.git;
            env = gitEnv;
            # Leave the calling script's PATH alone: it holds git's own helpers.
            inheritPath = true;
          };

          git-worktree-remove = pkgs.writeShellApplication {
            name = "git-worktree-remove";
            inheritPath = false;

            runtimeInputs = [
              git-configured
              pkgs.coreutils
              pkgs.tmux
            ];

            text = builtins.readFile ./git-worktree-remove.sh;
          };

          git-project-clone = pkgs.writeShellApplication {
            name = "git-project-clone";
            inheritPath = false;

            runtimeInputs = [
              git-configured
              pkgs.coreutils
              pkgs.openssh # git fetch over ssh:// shells out to it
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
          env = gitEnv;
          runtimeInputs = deps;
          # Must stay: git resolves core.editor (nvim) and the `sci`/`find` aliases'
          # helpers off the ambient PATH; deps deliberately omits them.
          inheritPath = true;
        }
      ) { };
    };
}

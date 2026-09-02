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
      ) { };
    };
}

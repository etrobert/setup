_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.git-worktree-add = pkgs.writeShellApplication {
        name = "git-worktree-add";
        # Hands its PATH to the tmux session tmux-sessionizer creates; clearing it
        # leaves that session without nvim, zsh or anything else on PATH.
        inheritPath = true;

        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          self'.packages.tmux-sessionizer
        ];

        text = builtins.readFile ./git-worktree-add.sh;
      };
    };
}

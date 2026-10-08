_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.claude-new = pkgs.writeShellApplication {
        name = "claude-new";
        # Hands its PATH to the tmux session git-worktree-add creates.
        inheritPath = true;

        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.jq
          self'.packages.git-wrapped
          self'.packages.git-worktree-add
          self'.packages.neovim-wrapped
          self'.packages.tmux-wrapped
        ];

        text = builtins.readFile ./claude-new.sh;
      };
    };
}

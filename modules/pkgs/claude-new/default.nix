_: {
  perSystem =
    { self', ... }:
    {
      # Prefixed onto PATH, so the tmux session git-worktree-add creates keeps the rest.
      packages.claude-new = self'.legacyPackages.writers.writeTsBin "claude-new" {
        runtimeInputs = [
          self'.packages.git-wrapped
          self'.packages.git-worktree-add
          self'.packages.neovim-wrapped
          self'.packages.tmux-wrapped
        ];
      } (builtins.readFile ./claude-new.ts);
    };
}

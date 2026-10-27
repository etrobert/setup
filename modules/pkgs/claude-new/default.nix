_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.claude-new = self'.legacyPackages.writers.writeNuBin "claude-new" {
        runtimeInputs = with self'.packages; [
          git-wrapped
          git-worktree-add
          neovim-wrapped
          pkgs.tmux
        ];
      } (builtins.readFile ./claude-new.nu);
    };
}

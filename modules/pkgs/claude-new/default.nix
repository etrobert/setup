_: {
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.claude-new = self'.legacyPackages.writers.writeNuBin "claude-new" {
        # Prefix, not replace: the tmux session git-worktree-add creates inherits it.
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          (lib.makeBinPath [
            self'.packages.git-wrapped
            self'.packages.git-worktree-add
            self'.packages.neovim-wrapped
            self'.packages.tmux-wrapped
          ])
        ];
      } (builtins.readFile ./claude-new.nu);
    };
}

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
          (lib.makeBinPath (
            with self'.packages;
            [
              git-wrapped
              git-worktree-add
              neovim-wrapped
              pkgs.tmux
            ]
          ))
        ];
      } (builtins.readFile ./claude-new.nu);
    };
}

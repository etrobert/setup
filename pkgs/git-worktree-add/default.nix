_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.git-worktree-add = pkgs.callPackage ./package.nix {
        inherit self';
      };
    };
}

_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.git-find-commit = pkgs.callPackage ./package.nix {
        inherit (self'.packages) fzf-wrapped;
      };
    };
}

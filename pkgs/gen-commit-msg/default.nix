_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.gen-commit-msg = pkgs.callPackage ./package.nix {
        inherit self';
      };
    };
}

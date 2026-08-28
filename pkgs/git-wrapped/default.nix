_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.git-wrapped = pkgs.callPackage ./package.nix {
        inherit self';
      };
    };
}

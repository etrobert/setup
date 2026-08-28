_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.agents = pkgs.callPackage ./package.nix {
        inherit self';
      };
    };
}

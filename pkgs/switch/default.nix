_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.switch = pkgs.callPackage ./package.nix {
        inherit self';
      };
    };
}

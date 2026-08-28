_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.creme = pkgs.callPackage ./package.nix { };
    };
}

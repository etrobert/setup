_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.batr = pkgs.callPackage ./package.nix { };
    };
}

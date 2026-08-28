_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.add-asset = pkgs.callPackage ./package.nix { };
    };
}

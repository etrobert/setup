_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.check-bt-profile = pkgs.callPackage ./package.nix { };
    };
}

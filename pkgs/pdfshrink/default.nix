_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.pdfshrink = pkgs.callPackage ./package.nix { };
    };
}

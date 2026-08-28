_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.pm = pkgs.callPackage ./package.nix { };
    };
}

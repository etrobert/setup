_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.nixplatforms = pkgs.callPackage ./package.nix { };
    };
}

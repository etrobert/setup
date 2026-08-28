_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.ils = pkgs.callPackage ./package.nix { };
    };
}

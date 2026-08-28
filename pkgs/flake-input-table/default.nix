_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.flake-input-table = pkgs.callPackage ./package.nix { };
    };
}

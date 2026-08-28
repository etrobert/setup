_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.printline = pkgs.callPackage ./package.nix { };
    };
}

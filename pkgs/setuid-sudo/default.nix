_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.setuid-sudo = pkgs.callPackage ./package.nix { };
    };
}

_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.deadnix-errfmt = pkgs.callPackage ./package.nix { };
    };
}

_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.pimsync-wrapped = pkgs.callPackage ./package.nix { };
    };
}

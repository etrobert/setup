_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.ntfy-wrapped = pkgs.callPackage ./package.nix { };
    };
}

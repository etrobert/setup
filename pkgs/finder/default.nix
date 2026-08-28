_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        finder = pkgs.callPackage ./package.nix { };
      };
    };
}

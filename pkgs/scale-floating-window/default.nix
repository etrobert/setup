_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        scale-floating-window = pkgs.callPackage ./package.nix { };
      };
    };
}

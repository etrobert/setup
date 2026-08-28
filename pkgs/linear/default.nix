_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        linear = pkgs.callPackage ./package.nix { };
      };
    };
}

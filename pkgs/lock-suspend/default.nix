_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        lock-suspend = pkgs.callPackage ./package.nix { };
      };
    };
}

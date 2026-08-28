_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        resize-window = pkgs.callPackage ./package.nix { };
      };
    };
}

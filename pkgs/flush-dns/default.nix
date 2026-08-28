_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        flush-dns = pkgs.callPackage ./package.nix { };
      };
    };
}

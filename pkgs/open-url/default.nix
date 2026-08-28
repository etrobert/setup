_: {
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        open-url = pkgs.callPackage ./package.nix {
          inherit self';
        };
      };
    };
}

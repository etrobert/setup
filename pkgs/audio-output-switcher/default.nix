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
        audio-output-switcher = pkgs.callPackage ./package.nix {
          inherit (self'.packages) fzf-wrapped;
        };
      };
    };
}

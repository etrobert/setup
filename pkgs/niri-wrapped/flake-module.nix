{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) rec {
        niri-wrapped = pkgs.callPackage ./default.nix { inherit self'; };
        niri-wrapped-dev = niri-wrapped.override { dev = true; };
      };
    };
}

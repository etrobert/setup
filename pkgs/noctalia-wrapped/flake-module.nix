{ inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
        noctalia-wrapped = pkgs.callPackage ./default.nix {
          official-plugins = inputs.noctalia-official-plugins;
          community-plugins = inputs.noctalia-community-plugins;
        };
      };
    };
}

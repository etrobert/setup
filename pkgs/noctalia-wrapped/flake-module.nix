{ inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        noctalia-wrapped = pkgs.callPackage ./default.nix {
          official-plugins = inputs.noctalia-official-plugins;
          community-plugins = inputs.noctalia-community-plugins;
        };
      };
    };
}

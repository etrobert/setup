{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      inputs',
      ...
    }:
    {
      # Not meta.platforms: the zen-browser input has no darwin outputs, so this
      # cannot be constructed there at all — not even far enough to read meta.
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        zen-browser-wrapped = pkgs.callPackage ./default.nix { inherit self inputs'; };
      };
    };
}

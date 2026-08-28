# Not meta.platforms: the zen-browser input has no darwin outputs, so on darwin
# this cannot be constructed at all — not even far enough to read meta.
{
  callPackage,
  pkgs,
  lib,
  ...
}:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  zen-browser-wrapped = callPackage ./default.nix { };
}

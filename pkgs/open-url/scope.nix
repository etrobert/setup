# Takes zen-browser-wrapped, which does not exist on darwin, so this cannot be
# constructed there either — meta.platforms alone would come too late.
{
  callPackage,
  pkgs,
  lib,
  ...
}:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  open-url = callPackage ./default.nix { };
}

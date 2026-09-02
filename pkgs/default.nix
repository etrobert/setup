{ self, lib, ... }:
{
  flake.lib.onlySupported = import (self + /lib/only-supported.nix) { inherit lib; };

  # Takes pkgs because it needs symlinkJoin and the wrapper builders from it,
  # unlike onlySupported above.
  flake.lib.wrapPackage = pkgs: pkgs.callPackage (self + /lib/wrap-package.nix) { };

  # Every package is a directory holding a flake module that declares it; this
  # imports them.
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (./. + "/${name}/default.nix")
    ) (builtins.readDir ./.)
  );
}

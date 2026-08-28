{ self, lib, ... }:
{
  flake.lib.onlySupported = import (self + /lib/only-supported.nix) { inherit lib; };

  # Every package is a directory holding a flake module that declares it; this
  # imports them.
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (./. + "/${name}/default.nix")
    ) (builtins.readDir ./.)
  );
}

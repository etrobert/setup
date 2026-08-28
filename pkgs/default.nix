{ self, lib, ... }:
let
  entries = builtins.readDir ./.;
in
{
  flake.lib.onlySupported = import (self + /lib/only-supported.nix) { inherit lib; };

  # Every package is a flake module declaring itself, derivation included; this
  # imports them.
  imports =
    lib.mapAttrsToList (name: _: ./. + "/${name}") (
      lib.filterAttrs (
        name: type: type == "directory" && builtins.pathExists (./. + "/${name}/default.nix")
      ) entries
    )
    ++ lib.mapAttrsToList (name: _: ./. + "/${name}") (
      lib.filterAttrs (
        name: type: type != "directory" && name != "default.nix" && lib.hasSuffix ".nix" name
      ) entries
    );
}

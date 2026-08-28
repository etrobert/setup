{ lib, ... }:
let
  entries = builtins.readDir ./.;
in
{
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

{ lib, ... }:
{
  # Packages left here carry .nix files that are not flake modules, so the
  # importTree in flake.nix cannot take them. It imports each directory; nix
  # resolves that to default.nix, leaving the rest for the package to consume.
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}") (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (./. + "/${name}/default.nix")
    ) (builtins.readDir ./.)
  );
}

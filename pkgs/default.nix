{
  self,
  inputs,
  lib,
  ...
}:
let
  entries = builtins.readDir ./.;

  # A package with plumbing of its own owns it, in a flake-module.nix beside its
  # derivation.
  ownsWiring = name: builtins.pathExists (./. + "/${name}/flake-module.nix");

  # Everything else is a directory holding a default.nix, or a lone .nix file.
  discoverable = lib.filterAttrs (
    name: type:
    if type == "directory" then
      !ownsWiring name && builtins.pathExists (./. + "/${name}/default.nix")
    else
      name != "default.nix" && lib.hasSuffix ".nix" name
  ) entries;

  packageName = name: lib.removeSuffix ".nix" name;
in
{
  imports = lib.mapAttrsToList (name: _: ./. + "/${name}/flake-module.nix") (
    lib.filterAttrs (name: type: type == "directory" && ownsWiring name) entries
  );

  perSystem =
    {
      self',
      pkgs,
      lib,
      inputs',
      ...
    }:
    let
      # Our packages get a scope of their own, so one asks for another by name
      # in its argument list, the way it asks for anything from nixpkgs. The
      # flake arguments are in scope for the same reason.
      scope = lib.makeScope pkgs.newScope (
        final:
        {
          inherit
            self
            self'
            inputs
            inputs'
            ;
        }
        // lib.mapAttrs' (
          name: _: lib.nameValuePair (packageName name) (final.callPackage (./. + "/${name}") { })
        ) discoverable
      );

      names = lib.mapAttrsToList (name: _: packageName name) discoverable;
    in
    {
      # Each package says which platforms it supports; anything that does not
      # support this one is dropped rather than named here.
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) (lib.getAttrs names scope);
    };
}

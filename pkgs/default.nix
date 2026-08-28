{
  self,
  inputs,
  lib,
  ...
}:
let
  entries = builtins.readDir ./.;

  # A package that needs more than one callPackage call — variants, a
  # platform-dependent argument — says so in a scope.nix beside its derivation.
  # It gets the scope's callPackage, plus pkgs and lib for anything it must
  # decide before the scope exists, such as which entries it defines at all.
  ownsWiring = name: builtins.pathExists (./. + "/${name}/scope.nix");

  # Everything else is a directory holding a default.nix, or a lone .nix file.
  discoverable = lib.filterAttrs (
    name: type:
    if type == "directory" then
      !ownsWiring name && builtins.pathExists (./. + "/${name}/default.nix")
    else
      name != "default.nix" && lib.hasSuffix ".nix" name
  ) entries;

  scopeFiles = lib.mapAttrsToList (name: _: ./. + "/${name}/scope.nix") (
    lib.filterAttrs (name: type: type == "directory" && ownsWiring name) entries
  );

  packageName = name: lib.removeSuffix ".nix" name;
in
{
  perSystem =
    {
      pkgs,
      lib,
      inputs',
      ...
    }:
    let
      # Every package lives in one scope, so a package asks for another by name
      # in its argument list, the way it asks for anything from nixpkgs — with
      # no distinction between the two kinds. The flake arguments are in scope
      # for the same reason.
      scope = lib.makeScope pkgs.newScope (
        final:
        {
          inherit
            self
            inputs
            inputs'
            ;
        }
        // lib.mapAttrs' (
          name: _: lib.nameValuePair (packageName name) (final.callPackage (./. + "/${name}") { })
        ) discoverable
        // lib.mergeAttrsList (
          map (
            file:
            import file {
              inherit (final) callPackage;
              inherit
                pkgs
                lib
                inputs
                inputs'
                ;
            }
          ) scopeFiles
        )
      );
    in
    {
      # Each package says which platforms it supports; anything that does not
      # support this one is dropped rather than named here.
      packages = lib.filterAttrs (_: p: lib.isDerivation p && !p.meta.unsupported) scope;
    };
}

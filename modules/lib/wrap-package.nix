# `wrapPackage` as a declared perSystem option, so a call site reads
# `config.lib.wrapPackage { … }` with pkgs already bound. Under `lib` because it
# is a helper function, not settings — the same split home-manager uses for
# `config.lib.file.mkOutOfStoreSymlink` and friends.
{
  self,
  lib,
  flake-parts-lib,
  ...
}:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { pkgs, ... }:
    {
      options.lib.wrapPackage = lib.mkOption {
        type = lib.types.functionTo lib.types.package;
        readOnly = true;
        default = pkgs.callPackage (self + /lib/wrap-package.nix) { };
        description = "Wraps a package with config, env and PATH. See lib/wrap-package.nix.";
      };
    }
  );
}

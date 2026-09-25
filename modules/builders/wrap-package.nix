# Exposed beside our writers, under `legacyPackages.<system>`, where nixpkgs
# keeps its own builders: pkgs is bound there, so callers reach it as
# `self'.legacyPackages.wrapPackage` without threading pkgs through. A host
# module that needs it indexes by the host's system, as it already does for
# `self.packages.<system>`.
_: {
  perSystem =
    { pkgs, ... }:
    {
      legacyPackages.wrapPackage = pkgs.callPackage ./_wrap-package.nix { };
    };
}

_: {
  # Under `flake.lib` rather than a perSystem option, so host modules that build
  # a package from the host's own config can reach it too. Callers bind pkgs:
  # `self.lib.wrapPackage pkgs { … }`.
  flake.lib.wrapPackage = pkgs: pkgs.callPackage ./_wrap-package.nix { };
}

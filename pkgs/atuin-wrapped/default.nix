_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.atuin-wrapped = pkgs.callPackage ./package.nix { };
    };
}

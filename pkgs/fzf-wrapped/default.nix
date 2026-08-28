_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.fzf-wrapped = pkgs.callPackage ./package.nix { };
    };
}

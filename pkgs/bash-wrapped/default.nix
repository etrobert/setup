_: {
  perSystem =
    {
      pkgs,
      inputs',
      self',
      ...
    }:
    {
      packages.bash-wrapped = pkgs.callPackage ./package.nix {
        inherit inputs';
        inherit (self'.packages) fzf-wrapped;
      };
    };
}

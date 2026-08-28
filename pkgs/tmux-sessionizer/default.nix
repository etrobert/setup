_: {
  perSystem =
    {
      pkgs,
      inputs',
      self',
      ...
    }:
    {
      packages.tmux-sessionizer = pkgs.callPackage ./package.nix {
        inherit self';
        inherit inputs';
      };
    };
}

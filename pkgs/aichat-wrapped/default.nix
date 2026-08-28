_: {
  perSystem =
    {
      pkgs,
      inputs',
      self',
      ...
    }:
    {
      packages.aichat-wrapped = pkgs.callPackage ./package.nix {
        inherit self';
        inherit inputs';
      };
    };
}

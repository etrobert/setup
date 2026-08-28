_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.neovim-wrapped = pkgs.callPackage ./package.nix {
        inherit self';
      };
    };
}

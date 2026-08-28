_: {
  perSystem =
    {
      pkgs,
      inputs',
      self',
      ...
    }:
    {
      packages.zsh-wrapped = pkgs.callPackage ./package.nix {
        inherit inputs';
        inherit (self'.packages) atuin-wrapped fzf-wrapped;
      };
    };
}

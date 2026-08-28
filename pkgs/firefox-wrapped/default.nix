{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.firefox-wrapped = pkgs.callPackage ./package.nix {
        inherit self;
      };
    };
}

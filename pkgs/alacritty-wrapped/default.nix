_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.alacritty-wrapped = pkgs.callPackage ./package.nix { };
    };
}

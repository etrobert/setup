_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.tmux-wrapped = pkgs.callPackage ./package.nix { };
    };
}

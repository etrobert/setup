{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.git-wrapped = pkgs.callPackage ./default.nix { inherit self'; };
    };
}

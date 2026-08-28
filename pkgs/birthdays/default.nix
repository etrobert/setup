_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.birthdays = pkgs.callPackage ./package.nix { };
    };
}

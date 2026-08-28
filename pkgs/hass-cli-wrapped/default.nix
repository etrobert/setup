_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.hass-cli-wrapped = pkgs.callPackage ./package.nix { };
    };
}

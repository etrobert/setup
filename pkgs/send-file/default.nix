_: {
  perSystem =
    { pkgs, self', ... }:
    {
      packages.send-file = pkgs.callPackage ./package.nix {
        inherit (self'.packages) ntfy-wrapped;
      };
    };
}

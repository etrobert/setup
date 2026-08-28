{
  perSystem =
    { pkgs, ... }:
    {
      # nixpkgs' ghostty is Linux-only; darwin gets the upstream binary.
      packages.ghostty-wrapped = pkgs.callPackage ./default.nix {
        ghostty = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      };
    };
}

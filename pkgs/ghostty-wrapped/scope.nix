{ callPackage, pkgs, ... }:
{
  # nixpkgs' ghostty is Linux-only; darwin gets the upstream binary.
  ghostty-wrapped = callPackage ./default.nix {
    ghostty = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
  };
}

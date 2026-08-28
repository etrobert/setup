{ callPackage, ... }:
rec {
  niri-wrapped = callPackage ./default.nix { };
  niri-wrapped-dev = niri-wrapped.override { dev = true; };
}

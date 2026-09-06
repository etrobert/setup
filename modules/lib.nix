# flake-parts leaves `flake.lib` to the freeform `flake` type, which makes it a
# single raw value that only one module may define. Declaring it as an attrset
# lets each helper under modules/lib/ contribute its own attribute.

{ lib, ... }:
{
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Helper functions shared across the flake.";
  };
}

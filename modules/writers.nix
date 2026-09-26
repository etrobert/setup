# flake-parts types `legacyPackages` as lazyAttrsOf raw, which makes
# `legacyPackages.writers` a single raw value that only one module may define.
# Declaring it as an attrset lets each writer under modules/builders/
# contribute its own attribute. They sit under `writers` so that
# `.#writers.writeNuBin` resolves the way `nixpkgs#writers.writeNuBin` does.

{ flake-parts-lib, lib, ... }:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, ... }:
    {
      options.writers = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
        default = { };
        description = "Script writers, exposed as `legacyPackages.<system>.writers`.";
      };

      config.legacyPackages.writers = config.writers;
    }
  );
}

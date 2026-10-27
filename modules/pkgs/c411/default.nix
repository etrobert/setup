_: {
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    {
      packages.c411 = self'.legacyPackages.writers.writeNuBin "c411" {
        runtimeInputs = [ pkgs.transmission_4 ];
      } (builtins.readFile ./c411.nu);
    };
}

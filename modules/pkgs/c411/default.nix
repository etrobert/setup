_: {
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.c411 = self'.legacyPackages.writers.writeNuBin "c411" {
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          (lib.makeBinPath [ pkgs.transmission_4 ])
        ];
      } (builtins.readFile ./c411.nu);
    };
}

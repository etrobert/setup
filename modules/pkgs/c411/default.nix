_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.c411 = pkgs.writers.writeNuBin "c411" {
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          (lib.makeBinPath [ pkgs.transmission_4 ])
        ];
      } (builtins.readFile ./c411.nu);
    };
}

_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.nix-dead-packages = pkgs.writers.writeNuBin "nix-dead-packages" {
        # --set rather than --prefix: the script runs against exactly these tools.
        makeWrapperArgs = [
          "--set"
          "PATH"
          (lib.makeBinPath [
            pkgs.git
            pkgs.nix
          ])
        ];
      } ./nix-dead-packages.nu;
    };
}

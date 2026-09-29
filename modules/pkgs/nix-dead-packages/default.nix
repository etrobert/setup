{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.nix-dead-packages = self.lib.wrapPackage pkgs {
        package = pkgs.writers.writePython3Bin "nix-dead-packages" {
          # black wraps at 88 columns, flake8 complains past 79.
          flakeIgnore = [ "E501" ];
        } (builtins.readFile ./nix-dead-packages.py);
        runtimeInputs = with pkgs; [
          git
          nix
        ];
        # A writers.* script declares no platforms of its own.
        platforms = lib.platforms.all;
      };
    };
}

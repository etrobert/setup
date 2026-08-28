_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.birthdays = pkgs.writers.writePython3Bin "birthdays" {
        libraries = [ pkgs.python3Packages.vobject ];
      } (builtins.readFile ./birthdays.py);
    };
}

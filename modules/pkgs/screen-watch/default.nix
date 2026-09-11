# What to watch for stays in ~/.config/screen-watch, out of this public repo:
# the template is a crop of someone else's artwork.
{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages = self.lib.onlySupported {
        screen-watch = self.lib.wrapPackage pkgs {
          package = pkgs.writers.writePython3Bin "screen-watch" {
            libraries = [
              pkgs.python3Packages.numpy
              pkgs.python3Packages.opencv4
            ];
            # black wraps at 88 columns, flake8 complains past 79.
            flakeIgnore = [ "E501" ];
          } (builtins.readFile ./screen-watch.py);
          runtimeInputs = [
            pkgs.grim
            self'.packages.ntfy-wrapped
          ];
          # Wayland-only through grim.
          platforms = lib.platforms.linux;
        };
      };
    };
}

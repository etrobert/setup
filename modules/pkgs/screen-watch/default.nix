# What to watch for stays in ~/.config/screen-watch, out of this public repo:
# the template is a crop of someone else's artwork.
_: {
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.screen-watch = pkgs.writers.writePython3Bin "screen-watch" {
        libraries = [ pkgs.python3Packages.opencv4 ];
        # black wraps at 88 columns, flake8 complains past 79.
        flakeIgnore = [ "E501" ];
        makeWrapperArgs = [
          "--set"
          "PATH"
          (lib.makeBinPath [
            pkgs.grim
            self'.packages.ntfy-wrapped
          ])
        ];
      } (builtins.readFile ./screen-watch.py);
    };
}

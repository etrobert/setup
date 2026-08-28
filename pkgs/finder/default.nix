{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = self.lib.onlySupported {
        finder = pkgs.symlinkJoin {
          name = "finder";
          meta.platforms = lib.platforms.darwin;
          paths = [
            (pkgs.writeShellApplication {
              name = "finder-hidefiles";
              inheritPath = true;
              text = ''
                defaults write com.apple.finder AppleShowAllFiles NO
                killall Finder
              '';
            })
            (pkgs.writeShellApplication {
              name = "finder-showfiles";
              inheritPath = true;
              text = ''
                defaults write com.apple.finder AppleShowAllFiles YES
                killall Finder
              '';
            })
          ];
        };
      };
    };
}

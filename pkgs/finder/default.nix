_: {
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.filterAttrs (_: p: !p.meta.unsupported) {
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

{
  writeShellApplication,
  symlinkJoin,
  lib,
}:
symlinkJoin {
  name = "finder";
  meta.platforms = lib.platforms.darwin;
  paths = [
    (writeShellApplication {
      name = "finder-hidefiles";
      inheritPath = true;
      text = ''
        defaults write com.apple.finder AppleShowAllFiles NO
        killall Finder
      '';
    })
    (writeShellApplication {
      name = "finder-showfiles";
      inheritPath = true;
      text = ''
        defaults write com.apple.finder AppleShowAllFiles YES
        killall Finder
      '';
    })
  ];
}

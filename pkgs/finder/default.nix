{ writeShellApplication, symlinkJoin }:
symlinkJoin {
  name = "finder";
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

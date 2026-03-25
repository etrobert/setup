{ config, ... }:
{
  imports = [ ./common.nix ];

  home.homeDirectory = "/Users/${config.home.username}";

  home.file.".hushlogin".text = "";

  home.shellAliases = {
    bg = "open /Volumes/T7/Applications/Baldur\'s\ Gate\ 3.app/Contents/MacOS/Baldur\'s\ Gate\ 3\ GOG";
  };

  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:8384";
    settings = import ../../syncthing-settings.nix { dataDir = config.home.homeDirectory; };
  };
}

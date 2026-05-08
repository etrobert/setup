{ self, ... }:
{
  flake.homeModules.darwin =
    { config, ... }:
    {
      imports = [ self.homeModules.common ];

      home = {
        homeDirectory = "/Users/${config.home.username}";

        file.".hushlogin".text = "";

        shellAliases = {
          bg = "open /Volumes/T7/Applications/Baldur\'s\ Gate\ 3.app/Contents/MacOS/Baldur\'s\ Gate\ 3\ GOG";
        };
      };

      services.syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        settings = import ../../syncthing-settings.nix { dataDir = config.home.homeDirectory; };
      };
    };
}

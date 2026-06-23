{ self, ... }:
{
  flake.homeModules.darwin =
    { config, ... }:
    {
      imports = [ self.homeModules.common ];

      home = {
        homeDirectory = "/Users/${config.home.username}";
      };

      services.syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        settings = import (self + /lib/syncthing-settings.nix) { dataDir = config.home.homeDirectory; };
      };
    };
}

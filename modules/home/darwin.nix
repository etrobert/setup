{ self, ... }:
{
  flake.homeModules.darwin =
    { config, ... }:
    {
      home = {
        username = "soft";
        homeDirectory = "/Users/${config.home.username}";

        # This value determines the Home Manager release that your
        # configuration is compatible with. This helps avoid breakage
        # when a new Home Manager release introduces backwards
        # incompatible changes.
        #
        # You can update Home Manager without changing this value. See
        # the Home Manager release notes for a list of state version
        # changes in each release.
        stateVersion = "25.11";
      };

      services.syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        settings = import (self + /lib/syncthing-settings.nix) { dataDir = config.home.homeDirectory; };
      };
    };
}

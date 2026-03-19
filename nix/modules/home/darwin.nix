{ config, ... }:
{
  imports = [ ./common.nix ];

  home.file.".alias.darwin".source = ../../../alias/.alias.darwin;

  home.homeDirectory = "/Users/${config.home.username}";

  services.syncthing = {
    enable = true;
    settings = import ../../syncthing-settings.nix { dataDir = config.home.homeDirectory; };
  };
}

{ config, ... }:
{
  imports = [ ./common.nix ];

  home.homeDirectory = "/home/${config.home.username}";

  home.file = {
    ".alias.linux".source = ../../../alias/.alias.linux;
  };
}

{ config, ... }:
{
  imports = [ ./common.nix ];

  home.file.".alias.darwin".source = ../../../alias/.alias.darwin;

  home.homeDirectory = "/Users/${config.home.username}";
}

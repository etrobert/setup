{ config, ... }:
{
  imports = [ ./common.nix ];

  home.homeDirectory = "/Users/${config.home.username}";
}

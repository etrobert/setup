{ config, ... }:
{
  imports = [ ./common.nix ];

  home.homeDirectory = "/home/${config.home.username}";

  home.file.".alias.linux".source = ../../../alias/.alias.linux;

  # Ensures XDG_DATA_DIRS includes the profile share directory
  # so app launchers (wofi, rofi) can find .desktop files
  xdg.mime.enable = true;
}

{ config, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  imports = [ ./common.nix ];

  home.homeDirectory = "/home/${config.home.username}";

  home.file = {
    ".alias.linux".source = ../../../alias/.alias.linux;

    ".config/waybar/config.jsonc".source =
      mkOutOfStoreSymlink "/home/soft/setup/waybar/.config/waybar/config.jsonc";
    ".config/waybar/style.css".source =
      mkOutOfStoreSymlink "/home/soft/setup/waybar/.config/waybar/style.css";

    ".config/mako/config".source = ../../../mako/.config/mako/config;
  };

  # Ensures XDG_DATA_DIRS includes the profile share directory
  # so app launchers (wofi, rofi) can find .desktop files
  xdg.mime.enable = true;
}

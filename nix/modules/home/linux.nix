{ config, ... }:
let
  symlink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/setup/${path}";
in
{
  imports = [ ./common.nix ];

  home.homeDirectory = "/home/${config.home.username}";

  home.file = {
    ".alias.linux".source = ../../../alias/.alias.linux;

    ".config/waybar/config.jsonc".source = symlink "waybar/.config/waybar/config.jsonc";
    ".config/waybar/style.css".source = symlink "waybar/.config/waybar/style.css";

    ".config/mako/config".source = ../../../mako/.config/mako/config;
  };

  # Ensures XDG_DATA_DIRS includes the profile share directory
  # so app launchers (wofi, rofi) can find .desktop files
  xdg.mime.enable = true;

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/sync/music";
    extraConfig = ''
      restore_paused "yes"
      auto_update "yes"
    '';
  };

  services.mpdris2 = {
    enable = true;
    notifications = true;
  };
}

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

    ".config/hypr/hyprland.conf".source = symlink "hyprland/.config/hypr/hyprland.conf";
    ".config/hypr/hyprpaper.conf".source = symlink "hyprland/.config/hypr/hyprpaper.conf";
    ".config/hypr/saint-levant.jpg".source = ../../../hyprland/.config/hypr/saint-levant.jpg;
  };

  # Ensures XDG_DATA_DIRS includes the profile share directory
  # so app launchers (wofi, rofi) can find .desktop files
  xdg.mime.enable = true;

  services = {
    mpd = {
      enable = true;
      musicDirectory = "${config.home.homeDirectory}/sync/music";
      extraConfig = ''
        restore_paused "yes"
        auto_update "yes"

        audio_output {
          type "pipewire"
          name "PipeWire"
        }
      '';
    };

    mpdris2 = {
      enable = true;
      notifications = true;
    };

    hypridle = {
      enable = true;
      settings = {
        listener = [
          {
            timeout = 900; # 15 minutes
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}

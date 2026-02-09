{ config, pkgs, ... }:
let
  symlink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/setup/${path}";

  albumArtWallpaper = pkgs.writeShellApplication {
    name = "album-art-wallpaper";
    runtimeInputs = with pkgs; [
      playerctl
      curl
      hyprland
    ];
    text = ''
      playerctl --follow metadata --format '{{mpris:artUrl}}' | while read -r url; do
        [ -z "$url" ] && continue
        curl -sL "$url" -o /tmp/albumart.jpg
        hyprctl hyprpaper wallpaper ",/tmp/albumart.jpg"
      done
    '';
  };
in
{
  imports = [ ./common.nix ];

  home.homeDirectory = "/home/${config.home.username}";

  home.sessionVariables.BROWSER = "firefox";

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
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "video/mp4" = [ "firefox.desktop" ];
      "x-scheme-handler/sgnl" = [ "signal.desktop" ];
      "x-scheme-handler/signalcaptcha" = [ "signal.desktop" ];
    };
  };

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

  systemd.user.services.album-art-wallpaper = {
    Unit.PartOf = [ "graphical-session.target" ];
    Service.ExecStart = "${albumArtWallpaper}/bin/album-art-wallpaper";
    Install.WantedBy = [ "graphical-session.target" ];
  };
}

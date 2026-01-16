{ pkgs, pronto, ... }:
{
  imports = [ ./common.nix ];

  # Enable I2C for ddcutil (external monitor brightness)
  hardware.i2c.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.graphics.enable = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "ctrl:nocaps";
  };

  console.useXkbConfig = true; # Apply XKB options (e.g. Caps -> Ctrl)

  programs.firefox = {
    enable = true;
    policies = {
      PasswordManagerEnabled = false;
      SearchEngines = {
        Default = "DuckDuckGo";
      };
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
          installation_mode = "force_installed";
          default_area = "menupanel";
        };
      };
    };
  };

  users.users.soft = {
    isNormalUser = true;
    description = "Etienne";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
    packages = [ ];
  };

  # NixOS-specific packages
  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "nixos-option" ''
      exec ${pkgs.nixos-option}/bin/nixos-option --flake "/home/soft/setup?dir=nixos#$(${pkgs.nettools}/bin/hostname)" "$@"
    '')
    brightnessctl
    ddcutil
    ghostty
    grim
    heroic
    hyprpaper
    mako
    pavucontrol
    playerctl
    slurp
    waybar
    wl-clipboard
    wofi
  ];

  programs.hyprland.enable = true;

  services.openssh.enable = true;
}

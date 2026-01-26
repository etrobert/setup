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

  security.rtkit.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "ctrl:nocaps";
  };

  console.useXkbConfig = true; # Apply XKB options (e.g. Caps -> Ctrl)

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 10d";
  };

  nix.settings.auto-optimise-store = true;

  zramSwap.enable = true;

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
    (import ./strip-json-comments-cli { inherit pkgs; })
    # See https://github.com/NixOS/nixpkgs/issues/436214
    # TL;DR The flake should probably be at the root of the repo
    # Until I fix it we have this wrapper
    (pkgs.writeShellScriptBin "nixos-option" ''
      exec ${pkgs.nixos-option}/bin/nixos-option --flake "$HOME/setup?dir=nix#$(${pkgs.nettools}/bin/hostname)" "$@"
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
    signal-desktop
    slurp
    waybar
    wl-clipboard
    wofi
  ];

  programs.hyprland.enable = true;

  services.openssh.enable = true;
}

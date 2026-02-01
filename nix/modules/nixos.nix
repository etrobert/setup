{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  system.activationScripts.nixos-symlink.text = ''
    ln --symbolic --force --no-dereference /home/soft/setup/nix /etc/nixos
  '';

  hardware = {
    # Enable I2C for ddcutil (external monitor brightness)
    i2c.enable = true;

    # Enable bluetooth
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;

    graphics.enable = true;
  };

  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      environmentFiles = [ "/run/agenix/wifi-soft" ];
      profiles.soft = {
        connection = {
          id = "soft";
          type = "wifi";
        };
        wifi = {
          ssid = "soft";
          mode = "infrastructure";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$WIFI_PASSWORD";
        };
      };
    };
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  security.rtkit.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "ctrl:nocaps";
  };

  services.syncthing = {
    enable = true;
    user = "soft";
    dataDir = "/home/soft";
    openDefaultPorts = true;
    settings = {
      devices = {
        "phone" = {
          id = "TLA3FU2-APJUQAC-EBS2B2Q-FAQ664L-KKEHB4A-L7QRUGA-R6UH3RN-ELAAQQB";
        };
        "leod" = {
          id = "5DCR24L-XI2U2AF-7AMMGXE-S4R7TQK-PDOYLGT-5UZLZNV-SERXLIT-BJ6QEAY";
        };
      };
      folders = {
        "sync" = {
          path = "/home/soft/sync";
          devices = [
            "phone"
            "leod"
          ];
          versioning = {
            type = "staggered";
            params.maxAge = "2592000"; # 30 days
          };
        };
      };
    };
  };

  console.useXkbConfig = true; # Apply XKB options (e.g. Caps -> Ctrl)

  nix.gc.dates = "daily";

  nix.settings.auto-optimise-store = true;

  zramSwap.enable = true;

  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/toggle-cpu-governor";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

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
    (writeShellApplication {
      name = "toggle-cpu-governor";
      runtimeInputs = [
        coreutils
        linuxPackages.cpupower
        kmod # for modprobe called by cpupower
      ];
      inheritPath = false;
      text = builtins.readFile ../../cpupower/.local/bin/toggle-cpu-governor;
    })
    linuxPackages.cpupower
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

  age.secrets.wifi-soft = {
    file = ../secrets/wifi-soft.age;
  };

  services.openssh.enable = true;
}

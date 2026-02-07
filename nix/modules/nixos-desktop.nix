{ pkgs, ... }:
{
  boot.extraModulePackages = with pkgs.linuxPackages; [ ddcci-driver ];
  boot.kernelModules = [ "ddcci-backlight" ];

  # Register DDC/CI devices on I2C buses for backlight control
  # (auto-probing is unavailable on kernel 6.8+)
  # Source https://wiki.nixos.org/wiki/Backlight#DDC/CI
  services.udev.extraRules =
    let
      bash = "${pkgs.bash}/bin/bash";
      registerDdcci = ddcciDev: ''
        SUBSYSTEM=="i2c", ACTION=="add", ATTR{name}=="${ddcciDev}", RUN+="${bash} -c 'sleep 30; printf ddcci\ 0x37 > /sys/%p/new_device'"
      '';
    in
    builtins.concatStringsSep "\n" [
      (registerDdcci "AMDGPU DM i2c hw bus*") # AMD GPUs
      (registerDdcci "AUX *") # Intel GPUs (DisplayPort)
    ];

  hardware = {
    # Enable I2C for ddcutil (external monitor brightness)
    i2c.enable = true;

    # Enable bluetooth
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [
      "/run/agenix/wifi-soft"
      "/run/agenix/wifi-iphone-de-zeus"
    ];
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
    profiles.iphoneDeZeus = {
      connection = {
        id = "iPhone de Zeus";
        type = "wifi";
      };
      wifi = {
        ssid = "iPhone de Zeus";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$WIFI_PASSWORD_IPHONE_DE_ZEUS";
      };
    };
  };

  services.syncthing = {
    enable = true;
    user = "soft";
    dataDir = "/home/soft";
    openDefaultPorts = true;
    settings = {
      options.urAccepted = -1; # Disable usage reporting/telemetry
      devices = {
        "phone" = {
          id = "TLA3FU2-APJUQAC-EBS2B2Q-FAQ664L-KKEHB4A-L7QRUGA-R6UH3RN-ELAAQQB";
        };
        "leod" = {
          id = "5DCR24L-XI2U2AF-7AMMGXE-S4R7TQK-PDOYLGT-5UZLZNV-SERXLIT-BJ6QEAY";
        };
        "tower" = {
          id = "3IIJQ3X-2BY72RR-YVNBZBQ-OAB6PM5-SPS3WPG-MCPTFVD-YSQ33SS-X4Q5DA3";
        };
      };
      folders = {
        "sync" = {
          path = "/home/soft/sync";
          devices = [
            "phone"
            "leod"
            "tower"
          ];
          versioning = {
            type = "staggered";
            params.maxAge = "2592000"; # 30 days
          };
        };
      };
    };
  };

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

  environment.systemPackages = with pkgs; [
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
    (writeShellApplication {
      name = "get_weather.sh";
      runtimeInputs = [
        coreutils
        curl
        jq
      ];
      inheritPath = false;
      text = builtins.readFile ../../waybar/.local/bin/get_weather.sh;
    })
    (writeShellApplication {
      name = "brightness-control";
      runtimeInputs = [
        coreutils # cut & tr
        brightnessctl
        ddcutil
        hyprland
        libnotify
        jq
        util-linux # flock
      ];
      inheritPath = false;
      text = builtins.readFile ../../hyprland/.local/bin/brightness-control;
    })
    (writeShellApplication {
      name = "volume-control";
      runtimeInputs = [
        gawk
        gnugrep
        libnotify
        wireplumber
      ];
      inheritPath = false;
      text = builtins.readFile ../../hyprland/.local/bin/volume-control;
    })
    linuxPackages.cpupower
    brightnessctl
    ddcutil
    ghostty
    grim
    heroic
    hyprpaper
    mako
    mpc # Minimalist command line interface to MPD
    pavucontrol
    playerctl
    signal-desktop
    slurp
    waybar
    wl-clipboard
    wofi
  ];

  programs.hyprland.enable = true;

  services.xserver.displayManager.gdm.enable = true;

  age.secrets = {
    wifi-soft.file = ../secrets/wifi-soft.age;
    wifi-iphone-de-zeus.file = ../secrets/wifi-iphone-de-zeus.age;
  };
}

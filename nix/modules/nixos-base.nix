{ config, pkgs, ... }:
{
  imports = [ ./base.nix ];

  system.activationScripts.nixos-symlink.text = ''
    ln --symbolic --force --no-dereference /home/soft/setup/nix /etc/nixos
  '';

  # Automatic timezone based on geolocation
  services.automatic-timezoned.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  console.useXkbConfig = true; # Apply XKB options (e.g. Caps -> Ctrl)

  nix.gc.dates = "daily";

  nix.settings.auto-optimise-store = true;

  zramSwap.enable = true;

  age.secrets.tailscale-authkey.file = ../secrets/tailscale-authkey.age;

  services = {
    # Configure keymap in X11
    xserver.xkb = {
      layout = "us";
      variant = "";
      options = "ctrl:nocaps";
    };

    tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscale-authkey.path;
    };

    openssh.enable = true;

    syncthing = {
      enable = true;
      user = "soft";
      dataDir = "/home/soft";
      openDefaultPorts = true;
      settings = {
        options.urAccepted = -1; # Disable usage reporting/telemetry
        devices = {
          "phone".id = "TLA3FU2-APJUQAC-EBS2B2Q-FAQ664L-KKEHB4A-L7QRUGA-R6UH3RN-ELAAQQB";
          "leod".id = "5DCR24L-XI2U2AF-7AMMGXE-S4R7TQK-PDOYLGT-5UZLZNV-SERXLIT-BJ6QEAY";
          "tower".id = "3IIJQ3X-2BY72RR-YVNBZBQ-OAB6PM5-SPS3WPG-MCPTFVD-YSQ33SS-X4Q5DA3";
          "pi".id = "EOXLGRM-GCJUBN3-6HD656O-KYXFYEX-N425OIL-SLBL7XJ-VN2RSXW-F7VJMAI";
        };
        folders = {
          "sync" = {
            path = "/home/soft/sync";
            devices = [
              "phone"
              "leod"
              "tower"
              "pi"
            ];
            versioning = {
              type = "staggered";
              params.maxAge = "2592000"; # 30 days
            };
          };
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
  };
}

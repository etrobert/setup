{
  pkgs,
  lib,
  config,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    neovim
  ];

  imports = [
    ./hardware-configuration.nix
    ../../home-assistant.nix
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot = {
    loader.grub.enable = false;
    # Enables the generation of /boot/extlinux/extlinux.conf
    loader.generic-extlinux-compatible.enable = true;

    # Enable IP forwarding required for Tailscale exit node.
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:etrobert/setup/main?dir=nix#pi";
    flags = [
      "--accept-flake-config"
      "--print-build-logs"
    ];
    # dates = "4:40"; # default value
    randomizedDelaySec = "5min";
  };

  networking.hostName = "pi";

  networking.networkmanager.enable = true;

  services = {
    tailscale.extraUpFlags = [ "--advertise-exit-node" ];

    navidrome = {
      enable = true;
      settings = {
        Address = "0.0.0.0";
        MusicFolder = "/home/soft/sync/music";
        DataFolder = "/home/soft/.local/share/navidrome";
      };
      user = "soft";
    };

    cloudflared = {
      enable = true;
      tunnels."4086e663-124f-4446-af5b-82b80e029f32" = {
        credentialsFile = config.age.secrets.cloudflare-tunnel-pi.path;
        default = "http_status:404";
        ingress = {
          "etiennerobert.com" = "http://localhost:80";
        };
      };
    };
  };

  age.secrets.cloudflare-tunnel-pi.file = ../../../secrets/cloudflare-tunnel-pi.age;

  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "read-only";

  system.stateVersion = "25.11";
}

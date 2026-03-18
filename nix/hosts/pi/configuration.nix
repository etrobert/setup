{ pkgs, lib, ... }:

{
  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos-base.nix
    ../../modules/home-assistant.nix
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

  services.tailscale.extraUpFlags = [ "--advertise-exit-node" ];

  services.navidrome = {
    enable = true;
    settings = {
      Address = "0.0.0.0";
      MusicFolder = "/home/soft/sync/music";
      DataFolder = "/home/soft/.local/share/navidrome";
    };
    user = "soft";
  };

  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "read-only";

  users.users.soft.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJeCI4pCgGMAB9w8u3l0TLhCKdvi0sSd0AjckDr8/tgD etiennerobert@MacBook-Pro-3.local"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiLGjBlPoqRSzJ7KfEyMzJ3JRBqelOepsiL4ri9OqW soft@leod"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILe8/rx4MPrvwQBU1cy5qkhBgnRALS6Jzc9I20EcBnAx soft@nixos"
  ];

  system.stateVersion = "25.11";
}

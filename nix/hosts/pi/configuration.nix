{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos-base.nix
    ../../modules/home-assistant.nix
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "pi";

  networking.networkmanager.enable = true;

  # Enable IP forwarding required for Tailscale exit node.
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.tailscale.extraUpFlags = [ "--advertise-exit-node" ];

  users.users.soft.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiLGjBlPoqRSzJ7KfEyMzJ3JRBqelOepsiL4ri9OqW soft@leod"
  ];

  system.stateVersion = "25.11";
}

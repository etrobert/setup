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

  system.stateVersion = "25.11";
}

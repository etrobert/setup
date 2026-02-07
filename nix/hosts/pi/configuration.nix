{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  system.activationScripts.nixos-symlink.text = ''
    ln --symbolic --force --no-dereference /home/soft/setup/nix /etc/nixos
  '';

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "pi";

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  console.useXkbConfig = true;

  services.xserver.xkb.options = "eurosign:e,ctrl:nocaps";

  users.users.soft = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    vim
    wget
  ];

  services.openssh.enable = true;

  system.stateVersion = "25.11";
}

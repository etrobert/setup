# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  imports = [
    ../../modules/nixos-workstation.nix
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.configurationLimit = 3;

    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "leod"; # Define your hostname.

  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}

# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../home-assistant.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tower";

  # Static IP on the motherboard NIC so the link survives the monitor (and its
  # USB ethernet adapter) being turned off. DNS points at pi for split-horizon
  # resolution of internal *.etiennerobert.com names.
  networking.networkmanager.ensureProfiles.profiles."enp11s0-static" = {
    connection = {
      id = "enp11s0-static";
      type = "ethernet";
      interface-name = "enp11s0";
    };
    ipv4 = {
      method = "manual";
      address1 = "192.168.0.10/24,192.168.0.1";
      dns = "192.168.0.18;";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}

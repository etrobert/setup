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

  networking.networkmanager.ensureProfiles.profiles."enp13s0u1u4u3-static" = {
    connection = {
      id = "enp13s0u1u4u3-static";
      type = "ethernet";
      interface-name = "enp13s0u1u4u3";
    };
    ipv4 = {
      method = "manual";
      address1 = "192.168.0.130/24,192.168.0.1";
      dns = "192.168.0.18;";
    };
    ipv6 = {
      method = "manual";
      address1 = "fd00::130/64";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  services.ollama = {
    enable = true;
    loadModels = [ "qwen3:14b" ];
    syncModels = true;
  };
}

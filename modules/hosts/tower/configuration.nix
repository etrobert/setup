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

  # Docker daemon, for running containers (e.g. the nixos/nix image to get an
  # interactive Nix environment on machines without Nix).
  virtualisation.docker.enable = true;
  users.users.soft.extraGroups = [ "docker" ];

  # Keep a Claude 5h usage session always ticking over (see modules/claude-warmup.nix).
  services.claude-warmup.enable = true;

  services.sunshine = {
    enable = true;
    openFirewall = true;
  };

  networking.networkmanager = {
    # Disable WiFi: tower is a wired desktop on the static enp11s0 link below, so
    # WiFi only added a second IP on the same /24. That dual-homing intermittently
    # broke Home Assistant's zeroconf at startup (mDNS multicast ENODEV). See #281.
    unmanaged = [ "interface-name:wlp12s0" ];

    # Static IP on the motherboard NIC so the link survives the monitor (and its
    # USB ethernet adapter) being turned off. DNS points at pi for split-horizon
    # resolution of internal *.etiennerobert.com names.
    ensureProfiles.profiles."enp11s0-static" = {
      connection = {
        id = "enp11s0-static";
        type = "ethernet";
        interface-name = "enp11s0";
      };
      ipv4 = {
        method = "manual";
        address1 = "192.168.0.10/24,192.168.0.1";

        # Second address for LAN clients (published by pi's split-horizon
        # DNS): the Vodafone Station drops LAN-side traffic from WiFi clients
        # to .10 on the port-forwarded ports (80/443), but the filter is keyed
        # to the forward's target IP, so the same services on .11 pass. Keep
        # the port forwards themselves pointing at .10.
        address2 = "192.168.0.11/24";

        dns = "192.168.0.18;";
      };
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

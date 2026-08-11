# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, ... }:
{
  flake.nixosModules.towerConfiguration = {
    imports = [
      self.nixosModules.towerHardware
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "tower";

    # Overflow tier beneath zram (priority 5, profiles/nixos-base.nix): zram
    # keeps the hot pages, this absorbs the cold tail. An unset priority gets a
    # kernel-assigned negative value, which is below zram's 5.
    swapDevices = [
      {
        device = "/swapfile";
        size = 32 * 1024;
      }
    ];

    # Docker daemon, for running containers (e.g. the nixos/nix image to get an
    # interactive Nix environment on machines without Nix).
    virtualisation.docker.enable = true;
    users.users.soft.extraGroups = [ "docker" ];

    # Keep a Claude 5h usage session always ticking over
    # (see modules/features/claude-warmup.nix).
    services.claude-warmup.enable = true;

    services.sunshine = {
      enable = true;
      openFirewall = true;
    };

    networking.networkmanager = {
      # Keep tower single-homed on the motherboard NIC; a second IP on the same
      # /24 intermittently broke Home Assistant's zeroconf startup. See #281.
      unmanaged = [
        "type:wifi"
        "mac:c8:4b:d6:ce:4e:78" # monitor's built-in USB ethernet adapter
      ];

      # Static IP on the motherboard NIC so the link survives the monitor (and its
      # USB ethernet adapter) being turned off. DNS points at pi for split-horizon
      # resolution of internal *.etiennerobert.com names. Matched by MAC because
      # PCI renumbering renames the interface across kernel updates.
      ensureProfiles.profiles."lan-static" = {
        connection = {
          id = "lan-static";
          type = "ethernet";
        };

        ethernet.mac-address = "34:5A:60:E1:DA:11";

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
  };
}

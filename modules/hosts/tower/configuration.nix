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
    # Disable WiFi: tower is a wired desktop on the static bridge (br0) below, so
    # WiFi only added a second IP on the same /24. That dual-homing intermittently
    # broke Home Assistant's zeroconf at startup (mDNS multicast ENODEV). See #281.
    #
    # Also ignore the Dell U3223QE's USB ethernet adapter (by MAC): its jack is
    # cabled to tower's own br0 port, so managing it would give tower a second
    # DHCP address that hairpins through its own bridge — same dual-homing
    # problem as WiFi.
    unmanaged = [
      "interface-name:wlp12s0"
      "mac:C8:4B:D6:CE:4E:78"
    ];

    # tower bridges its two NICs (software switch): motherboard NIC to the
    # router, PCIe NIC to the monitor's ethernet jack, which serves the laptop
    # via the monitor's KVM. Replaces the external switch on the desk.
    ensureProfiles.profiles = {
      "br0" = {
        connection = {
          id = "br0";
          type = "bridge";
          interface-name = "br0";
        };

        bridge = {
          # No redundant links possible, so skip STP's ~30s of blocked
          # forwarding (listening + learning phases) on every activation.
          stp = false;

          # Pin the bridge MAC to the motherboard NIC's so the router's ARP
          # entry for .10 survives the cutover and later port additions.
          mac-address = "34:5A:60:E1:DA:11";
        };

        # Static IP so the link doesn't depend on external DHCP. DNS points at
        # pi for split-horizon resolution of internal *.etiennerobert.com names.
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

      "br0-port-uplink" = {
        connection = {
          id = "br0-port-uplink";
          type = "ethernet";
          interface-name = "enp11s0";
          master = "br0";
          slave-type = "bridge";
        };
      };

      # TODO: replace the interface name with the real one once the PCIe NIC
      # (TP-Link TX201) is installed (`ip -brief link`). Inert until then.
      "br0-port-monitor" = {
        connection = {
          id = "br0-port-monitor";
          type = "ethernet";
          interface-name = "enpXs0";
          master = "br0";
          slave-type = "bridge";
        };
      };
    };
  };

  # Docker loads br_netfilter and sets net.bridge.bridge-nf-call-iptables=1,
  # which routes br0's switched frames through the iptables FORWARD chain —
  # where Docker's policy is DROP. Accept intra-bridge traffic in DOCKER-USER,
  # the chain Docker reserves for user rules and never flushes. Created here in
  # case the firewall starts before the Docker daemon.
  networking.firewall.extraCommands = ''
    iptables --new-chain DOCKER-USER 2> /dev/null || true
    iptables --check DOCKER-USER --in-interface br0 --out-interface br0 --jump ACCEPT 2> /dev/null \
      || iptables --insert DOCKER-USER --in-interface br0 --out-interface br0 --jump ACCEPT
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}

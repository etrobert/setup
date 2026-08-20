_: {
  flake.nixosModules.lanDns =
    { config, lib, ... }:
    {
      options.services.lanDns = {
        enable = lib.mkEnableOption "LAN DHCP and split-horizon DNS via dnsmasq";
        interface = lib.mkOption {
          type = lib.types.str;
          default = "end0";
          description = "LAN interface to listen on";
        };
      };

      config = lib.mkIf config.services.lanDns.enable {
        services.dnsmasq = {
          enable = true;
          settings = {
            interface = config.services.lanDns.interface;
            # Tolerate the interface having no address yet. bind-interfaces
            # makes dnsmasq exit instead, which latched it dead on a boot race.
            bind-dynamic = true;
            no-resolv = true;
            server = [
              "1.1.1.1"
              "9.9.9.9"
            ];
            # .11 is tower's second address, required for WiFi clients: the
            # Vodafone Station drops LAN-side traffic from its WLAN to the
            # port-forward target (.10) on the forwarded ports (80/443), but
            # the filter is keyed to that target IP, so .11 passes.
            host-record = map (name: "${name}.etiennerobert.com,192.168.0.11") [
              "test"
              "creatures"
              "countdown"
              "files"
              "adele"
              "umami"
              "images"
              "rift"
              "rack"
              "nutricalc"
            ];
            dhcp-range = "192.168.0.50,192.168.0.250,12h";
            dhcp-option = [ "option:router,192.168.0.1" ];
          };
        };

        # Without this, dnsmasq starts unaddressed and drops SO_BINDTODEVICE on
        # the DHCP socket for good; bind-dynamic only covers the DNS listeners.
        systemd.services.dnsmasq = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
        };

        networking.firewall.interfaces.${config.services.lanDns.interface} = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [
            53
            67
          ];
        };
      };
    };
}

_: {
  flake.nixosModules.lanDns =
    { config, lib, ... }:
    {
      options.services.lanDns = {
        enable = lib.mkEnableOption "LAN split-horizon DNS via dnsmasq";
        interface = lib.mkOption {
          type = lib.types.str;
          default = "end0";
          description = "LAN interface to listen on for DNS and DHCP";
        };
        dhcp.enable = lib.mkEnableOption "DHCP server";
      };

      config = lib.mkIf config.services.lanDns.enable {
        services.dnsmasq = {
          enable = true;
          settings = {
            interface = config.services.lanDns.interface;
            bind-interfaces = true;
            no-resolv = true;
            server = [
              "1.1.1.1"
              "9.9.9.9"
            ];
            host-record = [
              "test.etiennerobert.com,192.168.0.130"
              "creatures.etiennerobert.com,192.168.0.130"
              "files.etiennerobert.com,192.168.0.130"
              "adele.etiennerobert.com,192.168.0.130"
            ];
          }
          // lib.optionalAttrs config.services.lanDns.dhcp.enable {
            dhcp-range = "192.168.0.50,192.168.0.250,12h";
            dhcp-option = [
              "option:router,192.168.0.1"
            ];
            dhcp-host = "c8:4b:d6:ce:4e:78,192.168.0.130";
            domain = "kabelbox.local";
          };
        };

        networking.firewall.interfaces.${config.services.lanDns.interface} = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ] ++ lib.optionals config.services.lanDns.dhcp.enable [ 67 ];
        };
      };
    };
}

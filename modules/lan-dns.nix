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
            bind-interfaces = true;
            no-resolv = true;
            server = [
              "1.1.1.1"
              "9.9.9.9"
            ];
            host-record = [
              "test.etiennerobert.com,192.168.0.10"
              "creatures.etiennerobert.com,192.168.0.10"
              "files.etiennerobert.com,192.168.0.10"
              "adele.etiennerobert.com,192.168.0.10"
              "umami.etiennerobert.com,192.168.0.10"
              "images.etiennerobert.com,192.168.0.10"
              "rift.etiennerobert.com,192.168.0.10"
            ];
            dhcp-range = "192.168.0.50,192.168.0.250,12h";
            dhcp-option = [ "option:router,192.168.0.1" ];
          };
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

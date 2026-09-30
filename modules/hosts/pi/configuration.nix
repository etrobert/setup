{ self, ... }:

{
  flake.nixosModules.pi-configuration =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.ghostty.terminfo ];

      imports = [
        self.nixosModules.pi-hardware
      ];

      # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
      boot = {
        loader.grub.enable = false;
        # Enables the generation of /boot/extlinux/extlinux.conf
        loader.generic-extlinux-compatible.enable = true;
      };

      networking.hostName = "pi";

      networking.networkmanager = {
        enable = true;
        ensureProfiles.profiles."end0-static" = {
          connection = {
            id = "end0-static";
            type = "ethernet";
            interface-name = "end0";
          };
          ipv4 = {
            method = "manual";
            address1 = "192.168.0.18/24,192.168.0.1";
            dns = "1.1.1.1;9.9.9.9;";
          };
        };
      };

      services.lanDns = {
        enable = true;
        interface = "end0";
      };

      services.tailscale = {
        useRoutingFeatures = "server";
        extraSetFlags = [ "--advertise-exit-node" ];
        # `tailscale up` resets prefs it is not given
        extraUpFlags = [ "--advertise-exit-node" ];
      };

      # --netfilter-mode=nodivert leaves tailscaled's own masquerade chain unhooked
      networking.nat = {
        enable = true;
        enableIPv6 = true;
        internalInterfaces = [ "tailscale0" ];
        externalInterface = "end0";
      };

      time.timeZone = "Europe/Berlin";

      system.stateVersion = "25.11";
    };
}

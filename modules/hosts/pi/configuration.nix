{ self, ... }:

{
  flake.nixosModules.piConfiguration =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        ghostty.terminfo
        neovim
      ];

      imports = [
        self.nixosModules.piHardware
      ];

      # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
      boot = {
        loader.grub.enable = false;
        # Enables the generation of /boot/extlinux/extlinux.conf
        loader.generic-extlinux-compatible.enable = true;

        # Enable IP forwarding required for Tailscale exit node.
        kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
          "net.ipv6.conf.all.forwarding" = 1;
        };
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

      services = {
        lanDns = {
          enable = true;
          interface = "end0";
        };

        tailscale.extraUpFlags = [ "--advertise-exit-node" ];

        # Root lives on the SD card, so cap the journal rather than let it grow
        # to journald's default ceiling of 10% of the filesystem (~5.9G here).
        journald.extraConfig = "SystemMaxUse=256M";
      };

      system.stateVersion = "25.11";
    };
}

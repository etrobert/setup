{
  pkgs,
  lib,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    ghostty.terminfo
    neovim
  ];

  imports = [
    ./hardware-configuration.nix
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

  services.lanDns = {
    enable = true;
    interface = "end0";
  };

  services = {
    tailscale.extraUpFlags = [ "--advertise-exit-node" ];

    # comin polls the CI-gated `deploy` ref (fast-forwarded only after the
    # all-builds job succeeds) and deploys nixosConfigurations.pi within ~60s.
    comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/etrobert/setup.git";
          branches.main.name = "deploy";
        }
      ];
    };

    navidrome = {
      enable = true;
      settings = {
        Address = "0.0.0.0";
        MusicFolder = "/home/soft/sync/music";
        DataFolder = "/home/soft/.local/share/navidrome";
      };
      user = "soft";
    };
  };

  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce "read-only";

  system.stateVersion = "25.11";
}

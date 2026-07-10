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

  system.autoUpgrade = {
    enable = true;
    flake = "github:etrobert/setup/main#pi";
    flags = [
      "--accept-flake-config"
      "--print-build-logs"
    ];
    # dates = "4:40"; # default value
    randomizedDelaySec = "5min";
  };

  # CI deploys to pi via nixos-rebuild --target-host root@pi. The key is pinned
  # to tower's addresses (Tailscale + LAN) so an exfiltrated key is useless
  # off tower. Private half lives only at tower:/home/soft/.ssh/pi-deploy.
  users.users.root.openssh.authorizedKeys.keys = [
    ''from="100.103.91.42,192.168.0.10" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINhMQOKCOSv2wUSKkWerWUQsj3e+8Ko1zNdm553hkIpM pi-deploy CI''
  ];

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

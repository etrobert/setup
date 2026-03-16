{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos-base.nix
    ../../modules/home-assistant.nix
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

  systemd.services.auto-update = {
    description = "Auto-update system from flake";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "auto-update" ''
        ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch \
          --flake github:etrobert/setup/main#pi \
          --accept-flake-config
      '';
    };
  };

  systemd.timers.auto-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "minutely";
      Persistent = true;
    };
  };

  networking.hostName = "pi";

  networking.networkmanager.enable = true;

  services.tailscale.extraUpFlags = [ "--advertise-exit-node" ];

  users.users.soft.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiLGjBlPoqRSzJ7KfEyMzJ3JRBqelOepsiL4ri9OqW soft@leod"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILe8/rx4MPrvwQBU1cy5qkhBgnRALS6Jzc9I20EcBnAx soft@nixos"
  ];

  system.stateVersion = "25.11";
}

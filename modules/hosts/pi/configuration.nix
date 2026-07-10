{
  pkgs,
  lib,
  ...
}:

let
  deployGate = pkgs.writeShellApplication {
    name = "pi-deploy-gate";

    runtimeInputs = [
      pkgs.gitMinimal
      pkgs.coreutils
    ];

    inheritPath = false;

    text = ''
      state_dir=/var/lib/nixos-upgrade
      last_rev="$state_dir/last-deployed-rev"
      pending_rev="$state_dir/pending-rev"
      deploy_url=https://github.com/etrobert/setup.git

      case "$1" in
        check)
          rev=$(git ls-remote "$deploy_url" deploy | cut --fields=1)
          if [ -z "$rev" ]; then
            echo "could not resolve deploy ref; skipping" >&2
            exit 1
          fi
          if [ -f "$last_rev" ] && [ "$rev" = "$(cat "$last_rev")" ]; then
            echo "deploy $rev already live; skipping"
            exit 1
          fi
          echo "$rev" > "$pending_rev"
          echo "deploy $rev differs from live; upgrading"
          ;;
        record)
          if [ -f "$pending_rev" ]; then
            mv "$pending_rev" "$last_rev"
          fi
          ;;
        *)
          echo "usage: pi-deploy-gate {check|record}" >&2
          exit 2
          ;;
      esac
    '';
  };
in
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
    flake = "github:etrobert/setup/deploy#pi";
    flags = [
      "--accept-flake-config"
      "--print-build-logs"
    ];
    dates = "*:0/1"; # every minute
  };

  systemd.services.nixos-upgrade.serviceConfig = {
    StateDirectory = "nixos-upgrade";
    ExecCondition = "${lib.getExe deployGate} check";
    ExecStartPost = "${lib.getExe deployGate} record";
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

{
  pkgs,
  lib,
  ...
}:

let
  # Gates the autoUpgrade timer on the `deploy` ref, which CI fast-forwards only
  # after all-builds passes. `check` (ExecCondition) skips the run unless deploy
  # advanced past the last live rev, so idle minute-ticks cost one `git
  # ls-remote` instead of a 3-5 min flake eval on the Pi 4. `record`
  # (ExecStartPost) promotes the gated rev after a successful switch.
  #
  # `check` records the rev it gated on, not a fresh ls-remote at the end: a rev
  # pushed mid-deploy is then caught on the next tick rather than lost.
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

      case "''${1:-}" in
        check)
          mkdir -p "$state_dir"
          rev=$(git ls-remote "$deploy_url" deploy | cut --fields=1) || true
          if [ -z "$rev" ]; then
            echo "could not resolve deploy ref; skipping" >&2
            exit 1
          fi
          if [ -f "$last_rev" ] && [ "$rev" = "$(cat "$last_rev")" ]; then
            echo "deploy $rev already live; skipping"
            exit 1
          fi
          printf '%s\n' "$rev" > "$pending_rev"
          echo "deploy $rev differs from live; upgrading"
          ;;
        record)
          if [ -f "$pending_rev" ]; then
            mv --force "$pending_rev" "$last_rev"
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
    dates = "*:0/1";
  };

  systemd.services.nixos-upgrade.serviceConfig = {
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

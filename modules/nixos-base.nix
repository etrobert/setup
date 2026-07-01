_: {
  flake.nixosModules.nixosBase =
    {
      self,
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit (self.packages.${system}) zsh-wrapped;
    in
    {
      system.activationScripts.nixos-symlink.text = /* bash */ ''
        ln --symbolic --force --no-dereference /home/soft/setup /etc/nixos
      '';

      # Automatic timezone based on geolocation
      services.automatic-timezoned.enable = true;

      i18n.defaultLocale = "en_US.UTF-8";

      console.useXkbConfig = true; # Apply XKB options to the TTY too

      nix.settings.trusted-users = [ "@wheel" ];

      nix.gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 10d";
      };

      zramSwap.enable = true;

      # systemd-oomd runs by default but acts only on cgroups marked with
      # ManagedOOM* properties — with none marked (the NixOS default) the
      # kernel OOM killer acts alone, firing too late and killing by
      # per-process score rather than by which workload causes the pressure.
      systemd.oomd = {
        enableRootSlice = true;
        enableSystemSlice = true;
        enableUserSlices = true;
      };

      # Shorten how long the user systemd manager waits for an unresponsive
      # user-session process to exit on SIGTERM before SIGKILL (default 90s).
      # Motivating case: claude-code's background daemon and its bg-spare PTY
      # hosts don't exit promptly on SIGTERM, so a tmux pane running claude
      # would stall poweroff for the full 90s. This is general workstation
      # policy, not a claude-specific patch — system units keep the 90s default
      # (databases/VMs that need a long graceful flush live there), and any user
      # unit that genuinely needs longer overrides TimeoutStopSec itself.
      systemd.user.settings.Manager = {
        DefaultTimeoutStopSec = "15s";
      };

      services = {
        kanata = {
          enable = true;
          keyboards.default = {
            config = /* scheme */ ''
              (defsrc
                caps
                esc
              )

              (deflayer base
                (tap-hold-press 0 200 esc lctl)
                (tap-hold 200 200 esc caps)
              )
            '';
            extraDefCfg = "process-unmapped-keys yes";
          };
        };

        # Right Alt as a Compose key, so e.g. RAlt e ' types é. niri inherits
        # this via locale1 (its xkb block is empty). terminate:ctrl_alt_bksp is
        # the NixOS default, kept here since setting this replaces it.
        xserver.xkb.options = "terminate:ctrl_alt_bksp,compose:ralt";

        tailscale = {
          enable = true;
          authKeyFile = config.age.secrets.tailscale-authkey.path;
        };

        syncthing = {
          enable = true;
          user = "soft";
          dataDir = "/home/soft";
          openDefaultPorts = true;
          guiAddress = "0.0.0.0:8384";
          settings = import (self + /lib/syncthing-settings.nix) { dataDir = "/home/soft"; };
        };

      };

      environment.shells = [ zsh-wrapped ];

      users.mutableUsers = false;

      users.users.soft = {
        isNormalUser = true;
        description = "Etienne";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        hashedPasswordFile = config.age.secrets.soft-password.path;
        shell = lib.getExe zsh-wrapped;
      };

      age.secrets.soft-password = {
        file = ../secrets/soft-password.age;
      };

      programs.nh = {
        enable = true;
        flake = "/home/soft/setup";
      };
    };
}

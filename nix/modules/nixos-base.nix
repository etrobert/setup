_: {
  flake.nixosModules.nixosBase =
    { pkgs, config, ... }:
    {
      system.activationScripts.nixos-symlink.text = ''
        ln --symbolic --force --no-dereference /home/soft/setup/nix /etc/nixos
      '';

      # Automatic timezone based on geolocation
      services.automatic-timezoned.enable = true;

      i18n.defaultLocale = "en_US.UTF-8";

      console.useXkbConfig = true; # Apply XKB options (e.g. Caps -> Ctrl)

      nix.gc.dates = "daily";

      zramSwap.enable = true;

      services = {
        kanata = {
          enable = true;
          keyboards.default = {
            config = /* scheme */ ''
              (defsrc
                caps
              )

              (deflayer base
                (tap-hold-press 0 200 esc lctl)
              )
            '';
            extraDefCfg = "process-unmapped-keys yes";
          };
        };

        tailscale = {
          enable = true;
          authKeyFile = config.age.secrets.tailscale-authkey.path;
        };

        openssh.enable = true;

        syncthing = {
          enable = true;
          user = "soft";
          dataDir = "/home/soft";
          openDefaultPorts = true;
          guiAddress = "0.0.0.0:8384";
          settings = import ../syncthing-settings.nix { dataDir = "/home/soft"; };
        };

      };

      users.users.soft = {
        isNormalUser = true;
        description = "Etienne";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.zsh;

        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILB4WoJruElpVJyHuniZ+NO2NZXjh2gzklJAAShCzrgi soft@aaron.local"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXiLGjBlPoqRSzJ7KfEyMzJ3JRBqelOepsiL4ri9OqW soft@leod"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILe8/rx4MPrvwQBU1cy5qkhBgnRALS6Jzc9I20EcBnAx soft@nixos"
        ];
      };
    };
}

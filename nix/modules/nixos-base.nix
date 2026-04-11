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
    };
}

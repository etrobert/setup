_: {
  flake.nixosModules.nixosBase =
    { pkgs, config, ... }:
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
              (defsrc caps a s d f j k l ;)

              (defhands
                (left  q w e r t a s d f g z x c v b)
                (right y u i o p h j k l ; n m , . / ))

              (defvar
                timeout 150
              )

              (deflayer base
                (tap-hold-press 0 200 esc lctl)

                (tap-hold-opposite-hand $timeout a lmet)
                (tap-hold-opposite-hand $timeout s lalt)
                (tap-hold-opposite-hand $timeout d lctl)
                (tap-hold-opposite-hand $timeout f lsft)

                (tap-hold-opposite-hand $timeout j rsft)
                (tap-hold-opposite-hand $timeout k rctl)
                (tap-hold-opposite-hand $timeout l lalt)
                (tap-hold-opposite-hand $timeout ; rmet)
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
      };
    };
}

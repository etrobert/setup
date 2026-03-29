_: {
  flake.nixosModules.nixosWorkstation =
    { self, pkgs, ... }:
    {
      imports = [ self.nixosModules.networkmanager ];

      boot.extraModulePackages = with pkgs.linuxPackages; [ ddcci-driver ];
      boot.kernelModules = [ "ddcci-backlight" ];

      services = {
        # Register DDC/CI devices on I2C buses for backlight control
        # (auto-probing is unavailable on kernel 6.8+)
        # Source https://wiki.nixos.org/wiki/Backlight#DDC/CI
        udev.extraRules =
          let
            bash = "${pkgs.bash}/bin/bash";
            registerDdcci = ddcciDev: ''
              SUBSYSTEM=="i2c", ACTION=="add", ATTR{name}=="${ddcciDev}", RUN+="${bash} -c 'sleep 30; printf ddcci\ 0x37 > /sys/%p/new_device'"
            '';
          in
          builtins.concatStringsSep "\n" [
            (registerDdcci "AMDGPU DM i2c hw bus*") # AMD GPUs
            (registerDdcci "AUX *") # Intel GPUs (DisplayPort)
          ];

        displayManager.gdm.enable = true;
      };

      hardware = {
        # Enable I2C for ddcutil (external monitor brightness)
        i2c.enable = true;

        # Enable bluetooth
        bluetooth.enable = true;
        bluetooth.powerOnBoot = true;
      };

      security.rtkit.enable = true;

      security.sudo.extraRules = [
        {
          groups = [ "wheel" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/toggle-cpu-governor";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      # NixOS workstation packages
      environment.systemPackages =
        let
          # See https://github.com/NixOS/nixpkgs/issues/436214
          # TL;DR The flake should probably be at the root of the repo
          # Until I fix it we have this wrapper
          nixos-option = pkgs.writeShellScriptBin "nixos-option" ''
            exec ${pkgs.nixos-option}/bin/nixos-option --flake "$HOME/setup?dir=nix#$(${pkgs.nettools}/bin/hostname)" "$@"
          '';

          customPackages = with self.packages.${pkgs.stdenv.hostPlatform.system}; [
            nixos-option
            toggle-cpu-governor
            waybar-wrapped
            brightness-control
            volume-control
            birthdays
            creme
            lock-suspend
            check-bt-profile
          ];

          externalPackages = with pkgs; [
            linuxPackages.cpupower
            brightnessctl
            chromium
            ddcutil
            firefoxpwa
            ghostty
            grim
            hyprpaper
            mako
            mpc # Minimalist command line interface to MPD
            pavucontrol
            pimsync
            playerctl
            signal-desktop
            slurp
            usbutils # provides lsusb
            whatsapp-electron
            wl-clipboard
            wofi
          ];
        in
        customPackages ++ externalPackages;

      programs = {
        hyprland.enable = true;
        hyprlock.enable = true;
      };

      age.secrets = {
        wifi-soft.file = ../secrets/wifi-soft.age;
        wifi-iphone-de-zeus.file = ../secrets/wifi-iphone-de-zeus.age;
        apple-pimsync-password = {
          owner = "soft";
          file = ../secrets/apple-pimsync-password.age;
        };
      };

      home-manager.users.soft = self.homeModules.linux;
    };
}

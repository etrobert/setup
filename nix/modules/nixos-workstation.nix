_: {
  flake.nixosModules.nixosWorkstation =
    {
      self,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      imports = [
        self.nixosModules.networkmanager
        self.nixosModules.pimsync
      ];

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

      systemd.user = {
        services.album-art-wallpaper = {
          partOf = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig.ExecStart = lib.getExe self.packages.${system}.album-art-wallpaper;
        };

        tmpfiles.rules = [ "d %h/.local/share/contacts 0700 - - -" ];
      };

      # NixOS workstation packages
      environment.systemPackages =
        let
          # See https://github.com/NixOS/nixpkgs/issues/436214
          # TL;DR The flake should probably be at the root of the repo
          # Until I fix it we have this wrapper
          nixos-option = pkgs.writeShellScriptBin "nixos-option" ''
            exec ${pkgs.nixos-option}/bin/nixos-option --flake "$HOME/setup?dir=nix#$(${pkgs.nettools}/bin/hostname)" "$@"
          '';

          customPackages = with self.packages.${system}; [
            nixos-option
            toggle-cpu-governor
            waybar-wrapped
            mako-wrapped
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
            mpc # Minimalist command line interface to MPD
            pavucontrol
            playerctl
            signal-desktop
            slurp
            usbutils # provides lsusb
            whatsapp-electron
            wl-clipboard
          ];
        in
        customPackages ++ externalPackages;

      programs = {
        niri = {
          enable = true;
          package = self.packages.${system}.niri-wrapped-dev; # TODO: Move out of dev
        };
        hyprlock.enable = true;
      };

      home-manager.users.soft = self.homeModules.linux;
    };
}

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
        self.nixosModules.darkman
      ];

      boot.extraModulePackages = with pkgs.linuxPackages; [ ddcci-driver ];
      boot.kernelModules = [ "ddcci-backlight" ];

      # Required for Spotify Connect to discover LAN devices (e.g. Sonos) via mDNS
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

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
        services = {
          waybar = {
            after = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              ExecStart = lib.getExe self.packages.${system}.waybar-wrapped;
              Restart = "on-failure";
            };
          };

          hyprpaper = {
            after = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              ExecStart = lib.getExe self.packages.${system}.hyprpaper-wrapped;
              Restart = "on-failure";
            };
          };

          album-art-wallpaper = {
            partOf = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig.ExecStart = lib.getExe self.packages.${system}.album-art-wallpaper;
          };
        };

        tmpfiles.rules = [ "d %h/.local/share/contacts 0700 - - -" ];
      };

      # NixOS workstation packages
      environment.systemPackages =
        let
          customPackages = with self.packages.${system}; [
            audio-output-switcher
            toggle-cpu-governor
            waybar-wrapped
            mako-wrapped
            brightness-control
            volume-control
            birthdays
            creme
            lock-suspend
            check-bt-profile
            zen-browser-wrapped
            ghostty-wrapped
          ];

          externalPackages = with pkgs; [
            linuxPackages.cpupower
            bambu-studio
            brightnessctl
            chromium
            ddcutil
            firefoxpwa
            gnome-power-manager # TODO: find a better one
            kdePackages.okular
            grim
            mpc # Minimalist command line interface to MPD
            pavucontrol
            playerctl
            slurp
            usbutils # provides lsusb
            whatsapp-electron
            wl-clipboard
          ];
        in
        customPackages ++ externalPackages;

      environment = {
        sessionVariables.BROWSER = "zen";

        etc."xdg/mimeapps.list".text = /* ini */ ''
          [Default Applications]
          x-scheme-handler/sgnl=signal.desktop
          x-scheme-handler/signalcaptcha=signal.desktop
          text/html=zen.desktop
          x-scheme-handler/http=zen.desktop
          x-scheme-handler/https=zen.desktop
          x-scheme-handler/about=zen.desktop
          x-scheme-handler/unknown=zen.desktop
          application/pdf=zen.desktop
        '';
      };

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

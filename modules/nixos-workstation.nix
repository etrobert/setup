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
        self.nixosModules.awww
        self.nixosModules.cachix-push
        self.nixosModules.copilot-api
      ];

      allowedUnfreePackages = [ "bambu-studio" ];

      boot.extraModulePackages = with pkgs.linuxPackages; [ ddcci-driver ];
      boot.kernelModules = [ "ddcci-backlight" ];

      services = {
        ollama = {
          enable = true;
          loadModels = [ "qwen3:8b" ];
          syncModels = true;
        };

        # Required for Spotify Connect to discover LAN devices (e.g. Sonos) via mDNS
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

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

        # tuigreet login prompt on vt1, then launch Niri. niri-session re-execs
        # through a login shell and imports the environment into systemd/D-Bus
        # itself; bash -l guarantees environment.sessionVariables are loaded.
        greetd = {
          enable = true;
          settings.default_session.command = ''${lib.getExe pkgs.tuigreet} --time --remember --asterisks --cmd "${pkgs.bash}/bin/bash -l -c niri-session"'';
        };
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

      systemd.packages = with self.packages.${system}; [
        waybar-wrapped
      ];

      systemd.user = {
        services = {
          waybar.wantedBy = [ "graphical-session.target" ];

          # Prevent nixos-rebuild switch from restarting niri mid-session.
          # Without this, switching causes a ghost niri to start (session inactive)
          # which then blocks the legitimate niri when you log back in.
          niri.restartIfChanged = false;

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
            open-url
          ];

          externalPackages = with pkgs; [
            linuxPackages.cpupower
            bambu-studio
            bitwarden-desktop
            brightnessctl
            chromium
            ddcutil
            gnome-power-manager # TODO: find a better one
            kdePackages.okular
            grim
            mpc # Minimalist command line interface to MPD
            mpv
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
        sessionVariables.BROWSER = "open-url";

        etc."xdg/mimeapps.list".text = /* ini */ ''
          [Default Applications]
          x-scheme-handler/sgnl=signal.desktop
          x-scheme-handler/signalcaptcha=signal.desktop
          text/html=open-url.desktop
          x-scheme-handler/http=open-url.desktop
          x-scheme-handler/https=open-url.desktop
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

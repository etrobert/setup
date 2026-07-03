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
        self.nixosModules.mpd
        self.nixosModules.awww
        self.nixosModules.cachix-push
        self.nixosModules.copilot-api
        self.nixosModules.ntfyDesktop
        self.nixosModules.fileManager
      ];

      allowedUnfreePackages = [ "bambu-studio" ];

      boot.extraModulePackages = with pkgs.linuxPackages; [ ddcci-driver ];
      boot.kernelModules = [ "ddcci-backlight" ];

      services = {
        # Firmware updates from LVFS: fwupdmgr refresh / get-updates / update.
        # Lenovo publishes leod's system firmware there; MSI doesn't, so
        # tower's BIOS stays manual (M-Flash), but NVMe, UEFI dbx, and
        # peripheral updates still apply.
        fwupd.enable = true;

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

        # Re-run DDC/CI backlight registration whenever a monitor is connected
        # or powered on. The kernel emits a DRM "change" hotplug event; the
        # registration itself (and the boot-time pass) lives in the
        # ddcci-register service below. This replaces a one-shot udev "add" rule
        # that only fired at boot, so a monitor that was off at boot now gets
        # picked up when it comes up. ddcci can't auto-probe on kernel 6.8+.
        # Source https://wiki.nixos.org/wiki/Backlight#DDC/CI
        udev.extraRules = ''
          SUBSYSTEM=="drm", ACTION=="change", ENV{HOTPLUG}=="1", RUN+="${pkgs.systemd}/bin/systemctl start --no-block ddcci-register.service"
        '';

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

      systemd = {
        packages = with self.packages.${system}; [
          waybar-wrapped
        ];

        # Instantiate ddcci backlight devices for any responsive DDC/CI monitor.
        # Triggered at boot and on DRM hotplug (see services.udev.extraRules).
        services.ddcci-register = {
          description = "Register DDC/CI monitors as backlight devices";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe self.packages.${system}.ddcci-register;
          };
        };

        user = {
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
            bemoji
            bitwarden-desktop
            brightnessctl
            chromium
            ddcutil
            gnome-power-manager # TODO: find a better one
            kdePackages.okular
            grim
            mpv
            pavucontrol
            playerctl
            slurp
            usbutils # provides lsusb
            whatsapp-electron
            wl-clipboard
            wtype
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

        hyprlock = {
          enable = true;
          # Supply the baked config via the wrapper; PAM and the binary remain
          # managed by the NixOS programs.hyprlock module.
          package = self.packages.${system}.hyprlock-wrapped;
        };
      };

      home-manager.users.soft = self.homeModules.linux;
    };
}

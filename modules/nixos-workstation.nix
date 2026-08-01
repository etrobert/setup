{ inputs, ... }:
{
  flake.nixosModules.nixosWorkstation =
    {
      self,
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;

      # leod's Intel UHD 620 can't hardware-decode AV1, so YouTube's AV1 streams
      # software-decode and peg the CPU. Disabling it makes sites serve VP9,
      # which this GPU decodes in hardware. Drop when leod goes.
      zen-browser = self.packages.${system}.zen-browser-wrapped.override {
        extraSettings = lib.optionalAttrs (config.networking.hostName == "leod") {
          "media.av1.enabled" = false;
        };
      };
    in
    {
      imports = [
        inputs.nix-flatpak.nixosModules.nix-flatpak
        self.nixosModules.networkmanager
        self.nixosModules.pimsync
        self.nixosModules.darkman
        self.nixosModules.mpd
        self.nixosModules.awww
        self.nixosModules.ddcci
        self.nixosModules.copilot-api
        self.nixosModules.ntfyDesktop
        self.nixosModules.fileManager
      ];

      services = {
        # Firmware updates from LVFS: fwupdmgr refresh / get-updates / update.
        # Lenovo publishes leod's system firmware there; MSI doesn't, so
        # tower's BIOS stays manual (M-Flash), but NVMe, UEFI dbx, and
        # peripheral updates still apply.
        fwupd.enable = true;

        # Bazaar's catalog comes from the system's flatpak remotes.
        flatpak = {
          enable = true;

          # Unfree in nixpkgs, so uncached and impractical to build locally;
          # Flathub ships prebuilt binaries.
          packages = [ "com.bambulab.BambuStudio" ];
        };

        # Required for Spotify Connect to discover LAN devices (e.g. Sonos) via mDNS
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        # tuigreet login prompt on vt1, then launch Niri. niri-session re-execs
        # through a login shell and imports the environment into systemd/D-Bus
        # itself; bash -l guarantees environment.sessionVariables are loaded.
        greetd = {
          enable = true;
          # Stops boot log lines from drawing over the tuigreet UI: resets the
          # VT at greeter start, and wires greetd's stdio to tty1 so systemd
          # counts the console as owned and stops printing status to it.
          useTextGreeter = true;
          settings.default_session.command = ''${lib.getExe pkgs.tuigreet} --time --remember --asterisks --cmd "${pkgs.bash}/bin/bash -l -c niri-session"'';
        };
      };

      hardware = {
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
              command = lib.getExe self.packages.${system}.toggle-cpu-governor;
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      systemd = {
        packages = with self.packages.${system}; [
          waybar-wrapped
        ];

        user = {
          services = {
            waybar.wantedBy = [ "graphical-session.target" ];

            # Prevent nixos-rebuild switch from restarting niri mid-session.
            # Without this, switching causes a ghost niri to start (session inactive)
            # which then blocks the legitimate niri when you log back in.
            niri.restartIfChanged = false;

            # Night-time color temperature; computes sunrise/sunset from
            # Berlin coordinates. Temperatures are wlsunset's defaults
            # (4000K night, 6500K day).
            wlsunset = {
              description = "Day/night screen color temperature";
              after = [ "graphical-session.target" ];
              partOf = [ "graphical-session.target" ];
              bindsTo = [ "graphical-session.target" ];
              wantedBy = [ "graphical-session.target" ];
              serviceConfig = {
                ExecStart = "${lib.getExe pkgs.wlsunset} -l 52.5 -L 13.4";
                Restart = "on-failure";
              };
            };

            cliphist = {
              after = [ "graphical-session.target" ];
              partOf = [ "graphical-session.target" ];
              wantedBy = [ "graphical-session.target" ];

              serviceConfig = {
                ExecStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} store";
                Restart = "on-failure";
              };
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
            zen-browser
            ghostty-wrapped
            open-url
          ];

          externalPackages = with pkgs; [
            linuxPackages.cpupower
            bazaar
            bemoji
            bibata-cursors
            brightnessctl
            chromium
            cliphist
            ddcutil
            gnome-power-manager # TODO: find a better one
            kdePackages.okular
            grim
            mpv
            orca-slicer
            pavucontrol
            playerctl
            slurp
            usbutils # provides lsusb
            whatsapp-electron
            wl-clipboard
            wtype
          ];

          # Trial only (#526) — the two other shells worth comparing against
          # noctalia 4.7.7, which programs.noctalia installs below. None of
          # these auto-start; run them by hand with waybar stopped.
          #
          #   noctalia-shell   noctalia 4.7.7   — runs on quickshell
          #   noctalia         noctalia 5.0.0-beta — standalone, no quickshell
          #   dms run          DankMaterialShell — quickshell config, needs
          #                    quickshell on PATH, hence it being listed here
          trialShells = with pkgs; [
            noctalia
            dms-shell
            quickshell
          ];
        in
        customPackages ++ externalPackages ++ trialShells;

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
        # GTK apps (waybar, pavucontrol, …) pick their cursor by GSettings
        # theme *name* and search XCURSOR_PATH for it — they ignore niri's
        # private cursor config. Point the name at Bibata and put the package
        # on the system profile (whose share/icons is on the global
        # XCURSOR_PATH) so every GTK app matches the compositor cursor.
        dconf = {
          enable = true;
          profiles.user.databases = [
            {
              settings."org/gnome/desktop/interface" = {
                cursor-theme = "Bibata-Modern-Classic";
                cursor-size = lib.gvariant.mkInt32 30;
              };
            }
          ];
        };

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

        # Trial only — a Quickshell-based shell (bar, launcher, notification
        # centre, lock screen) with a first-class niri backend, to compare
        # against waybar + fuzzel + mako before deciding whether to build our
        # own Quickshell config. See etrobert/setup#526.
        noctalia = {
          enable = true;

          # Pinned to 4.7.7 rather than the module's default pkgs.noctalia
          # (5.0.0-beta) because v5 dropped Quickshell: it is a standalone
          # binary with its QML compiled in, and its closure contains no
          # quickshell at all. 4.7.7 still runs on quickshell and ships its QML
          # readable, including the NiriService the trial is meant to evaluate.
          # Switch to the default if the goal is judging the product rather
          # than the platform.
          package = pkgs.noctalia-shell;

          # systemd.enable stays off deliberately: starting it with the session
          # would draw a second bar on top of waybar. Launch it by hand instead.

          # recommendedServices stays off too. It would enable
          # power-profiles-daemon, which manages CPU scaling itself and so
          # fights toggle-cpu-governor's cpupower calls. NetworkManager,
          # bluetooth and upower are already on.
        };
      };

      home-manager.users.soft = self.homeModules.linux;
    };
}

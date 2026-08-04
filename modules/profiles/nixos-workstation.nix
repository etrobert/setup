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
        self.nixosModules.noctaliaGreeter
        self.nixosModules.networkmanager
        self.nixosModules.pimsync
        self.nixosModules.darkman
        self.nixosModules.mpd
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
      };

      hardware = {
        # Enable bluetooth
        bluetooth.enable = true;
        bluetooth.powerOnBoot = true;

        # Grants the seat user an ACL on /dev/i2c-*, which noctalia's ddcutil
        # brightness backend needs to reach external monitors over DDC/CI.
        i2c.enable = true;
      };

      security.rtkit.enable = true;

      systemd = {
        user = {
          services = {
            # Prevent nixos-rebuild switch from restarting niri mid-session.
            # Without this, switching causes a ghost niri to start (session inactive)
            # which then blocks the legitimate niri when you log back in.
            niri.restartIfChanged = false;
          };

          tmpfiles.rules = [ "d %h/.local/share/contacts 0700 - - -" ];
        };
      };

      # NixOS workstation packages
      environment.systemPackages =
        let
          customPackages = with self.packages.${system}; [
            audio-output-switcher
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
            bibata-cursors
            chromium
            ddcutil
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
        # GTK apps (pavucontrol, thunar, …) pick their cursor
        # by GSettings theme *name* and search XCURSOR_PATH for it — they
        # ignore niri's private cursor config. Point the name at Bibata and
        # put the package on the system profile (whose share/icons is on the
        # global XCURSOR_PATH) so every GTK app matches the compositor cursor.
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

        # The desktop shell: bar, launcher, notification centre and lock
        # screen in one.
        #
        # The module's default package is v5, a native binary with niri
        # support compiled in (compositors::niri::NiriRuntime, driven off
        # NIRI_SOCKET).
        noctalia = {
          enable = true;
          systemd.enable = true;

          package = self.packages.${system}.noctalia-wrapped;

          recommendedServices.enable = true;
        };
      };
    };
}

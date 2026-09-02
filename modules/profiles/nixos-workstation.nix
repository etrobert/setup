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
    in
    {
      imports = [
        inputs.nix-flatpak.nixosModules.nix-flatpak
        self.nixosModules.firefox
        self.nixosModules.zen-browser
        self.nixosModules.noctalia
        self.nixosModules.networkmanager
        self.nixosModules.pimsync
        self.nixosModules.darkman
        self.nixosModules.mpd
        self.nixosModules.copilot-api
        self.nixosModules.ntfyDesktop
        self.nixosModules.fileManager
      ];

      documentation.doc.enable = false;

      # Absorbs the cold tail when zram fills. The tiering rests on two nixpkgs
      # defaults meeting: zram's priority 5 over the kernel-assigned negative
      # one a swapDevice gets when priority is unset.
      swapDevices = [
        {
          device = "/swapfile";
          size = 32 * 1024;
        }
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

        # Media keys run bare `playerctl`, which otherwise picks mpd (first
        # alphabetically) even when stopped; playerctld orders by activity.
        playerctld.enable = true;

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

        # Grants the seat user an ACL on /dev/i2c-*, which noctalia's ddcutil
        # brightness backend needs to reach external monitors over DDC/CI.
        i2c.enable = true;
      };

      security = {
        rtkit.enable = true;

        # soft is in the docker group with a rootful daemon, so the password
        # gates nothing an attacker can't walk around.
        sudo.wheelNeedsPassword = false;
      };

      systemd.user.tmpfiles.rules = [ "d %h/.local/share/contacts 0700 - - -" ];

      # NixOS workstation packages
      environment.systemPackages =
        let
          customPackages = with self.packages.${system}; [
            audio-output-switcher
            birthdays
            creme
            lock-suspend
            linear
            check-bt-profile
            ghostty-wrapped
            open-url
          ];

          externalPackages = with pkgs; [
            linuxPackages.cpupower
            bazaar
            bibata-cursors
            chromium
            ddcutil
            dmidecode
            kdePackages.okular
            mpv
            orca-slicer
            pavucontrol
            usbutils # provides lsusb
            # Drag-and-drop monitor layout over wlr-output-management
            wdisplays
            whatsapp-electron
            wl-clipboard
          ];

        in
        customPackages ++ externalPackages;

      environment = {
        sessionVariables.BROWSER = "open-url";

        etc."xdg/mimeapps.list".text = /* ini */ ''
          [Default Applications]
          # inode/* types describe filesystem objects rather than file
          # contents; inode/directory is what opening a folder resolves to.
          inode/directory=org.gnome.Nautilus.desktop
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
        chromium = {
          enable = true;

          extensions = [
            "fcoeoabgfenejglbffodgkkbkcdhcgfn" # Claude in Chrome
            "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
          ];
        };

        # GTK apps (pavucontrol, nautilus, …) pick their cursor
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

          package = config.wrappers.noctalia.wrapper;

          recommendedServices.enable = true;
        };
      };
    };
}

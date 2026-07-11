{
  self,
  pkgs,
  lib,
  ...
}:
let
  dockApps = import (self + /lib/dock-apps.nix);

  skhdAppBindings = lib.concatStringsSep "\n" (
    lib.imap1 (i: app: ''alt - ${toString i} : open "${app.path}"'') dockApps
  );

  wallpaper = self + /assets/saint-levant.jpg;

  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (self.packages.${system}) zsh-wrapped;
in
{
  allowedUnfreePackages = [
    "betterdisplay"
    "raycast"
  ];

  nix.settings.trusted-users = [ "@admin" ];

  # Daily, like nix.gc.dates = "daily" on the NixOS hosts (the darwin
  # default is weekly).
  nix.gc = {
    automatic = true;
    interval = {
      Hour = 3;
      Minute = 15;
    };
    options = "--delete-older-than 10d";
  };

  environment = {
    shells = [ zsh-wrapped ];

    systemPackages =
      (with pkgs; [
        betterdisplay
        watch
        raycast
        defaultbrowser
        ghostty-bin.terminfo
        moonlight-qt
        nh
        (writeShellApplication {
          # This is necessary because the darwin tailscale module does not include authkey option
          name = "tailscale-up";
          text = ''tailscale up --authkey "$(cat /run/agenix/tailscale-authkey)"'';
        })
      ])
      ++ (with self.packages.${system}; [
        flush-dns
        resize-window
        finder
        ghostty-wrapped
      ]);
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "aaron";
  networking.computerName = "aaron";

  system = {
    primaryUser = "soft";

    activationScripts.postActivation.text = ''
      ln --symbolic --force --no-dereference /Users/soft/setup /etc/nix-darwin

      # Suppress the login MOTD (replaces home-manager home.file.".hushlogin")
      touch /Users/soft/.hushlogin

      ${pkgs.defaultbrowser}/bin/defaultbrowser firefox

      # Set wallpaper
      launchctl asuser "$(id -u soft)" /usr/bin/osascript -e \
        'tell application "Finder" to set desktop picture to POSIX file "${wallpaper}"'
      # Restrict input sources to ABC only, clearing the history too so the
      # menu bar toggle disappears. Runs as soft since postActivation is root.
      sudo -u soft /usr/bin/defaults write com.apple.HIToolbox AppleEnabledInputSources -array \
        '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>252</integer><key>KeyboardLayout Name</key><string>ABC</string></dict>'
      sudo -u soft /usr/bin/defaults write com.apple.HIToolbox AppleInputSourceHistory -array \
        '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>252</integer><key>KeyboardLayout Name</key><string>ABC</string></dict>'
    '';

    # macOS-specific settings
    defaults = {
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        show-recents = false;
        tilesize = 80;
        persistent-apps = map (a: a.path) dockApps;
      };

      finder = {
        ShowPathbar = true;
      };

      controlcenter.Sound = true;

      NSGlobalDomain.InitialKeyRepeat = 15;
      NSGlobalDomain.KeyRepeat = 2;

      CustomUserPreferences = {
        "com.raycast.macos" = {
          # Cmd + Space
          raycastGlobalHotkey = "Command-49";
        };

        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Disable Spotlight search shortcut (Cmd + Space)
            "64" = {
              enabled = false;
            };
          };
        };

        # System default voice for `say` (and Spoken Content) — used by the
        # claude-speak Stop hook, which calls bare `say` with no -v. The premium
        # Zoe asset is a one-time GUI download (System Settings → Accessibility →
        # Spoken Content → Manage Voices); Apple ships no headless installer, so
        # this selection is reproducible but the asset is not. If absent, `say`
        # falls back to the default voice rather than erroring.
        "com.apple.Accessibility".SpokenContentDefaultVoiceSelectionsByLanguage = [
          "en"
          {
            "_type" = "Speech.VoiceSelection";
            "_version" = 0;
            boundLanguage = "en";
            voiceId = "com.apple.voice.premium.en-US.Zoe";
          }
        ];
      };
    };
  };

  # Note: doc says not to include the admin user
  users.knownUsers = [ "soft" ];

  users.users = {
    soft = {
      uid = 501;
      shell = lib.getExe zsh-wrapped;
      home = "/Users/soft";
    };
  };

  # Disable Homebrew's InfluxDB analytics -- the only part of the old `brew
  # shellenv` block worth keeping in Nix. nix-homebrew already provides `brew`
  # on PATH, brew self-derives HOMEBREW_PREFIX/CELLAR/REPOSITORY, and there are
  # no CLI formulae needing /opt/homebrew/bin on PATH. See issue #229.
  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  homebrew = {
    enable = true;
    casks = [
      "bambu-studio"
      "claude"
      "sonos"
      "vlc"
      "whatsapp"
    ];
  };

  launchd.daemons.caps-lock-to-control = {
    serviceConfig = {
      Label = "com.local.caps-lock-to-control";
      ProgramArguments = [
        "/usr/bin/hidutil"
        "property"
        "--set"
        ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}''
      ];
      RunAtLoad = true;
    };
  };

  services.skhd = {
    enable = true;
    skhdConfig = ''
      # Launch applications
      ${skhdAppBindings}

      # Map alt + hjkl to arrow keys
      alt - h : skhd -k "left"
      alt - j : skhd -k "down"
      alt - k : skhd -k "up"
      alt - l : skhd -k "right"

      alt + shift - h : skhd -k "shift-left"
      alt + shift - j : skhd -k "shift-down"
      alt + shift - k : skhd -k "shift-up"
      alt + shift - l : skhd -k "shift-right"
    '';
  };

  services.tailscale.enable = true;

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  home-manager.users.soft = self.homeModules.darwin;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}

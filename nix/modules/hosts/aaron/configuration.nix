{ pkgs, lib, ... }:
let
  dockApps = import ../../dock-apps.nix;

  skhdAppBindings = lib.concatStringsSep "\n" (
    lib.imap1 (i: app: ''alt - ${toString i} : open "${app.path}"'') dockApps
  );

  wallpaper = ../../../hyprland/.config/hypr/saint-levant.jpg;
in
{
  allowedUnfreePackages = [
    "betterdisplay"
    "raycast"
  ];

  nix.gc.interval = {
    Hour = 0;
    Minute = 0;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    primaryUser = "soft";

    activationScripts.postActivation.text = ''
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

      CustomUserPreferences."com.raycast.macos" = {
        # Cmd + Space
        raycastGlobalHotkey = "Command-49";
      };

      CustomUserPreferences."com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          # Disable Spotlight search shortcut (Cmd + Space)
          "64" = {
            enabled = false;
          };
        };
      };
    };
  };

  # Note: doc says not to include the admin user
  users.knownUsers = [ "soft" ];

  users.users = {
    soft = {
      uid = 505;
      shell = pkgs.zsh;
      home = "/Users/soft";
    };
  };

  homebrew = {
    enable = true;
    casks = [
      "ghostty"
    ];

    onActivation.cleanup = "zap";
  };

  environment.shells = [ pkgs.zsh ];

  environment.systemPackages = with pkgs; [
    betterdisplay
    watch
    raycast
    defaultbrowser

    (writeShellApplication {
      # This is necessary because the darwin tailscale module does not include authkey option
      name = "tailscale-up";
      text = "tailscale up --authkey \"$(cat /run/agenix/tailscale-authkey)\"";
    })
  ];

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

  # Open Raycast at login
  launchd.user.agents.raycast.serviceConfig = {
    ProgramArguments = [
      "/usr/bin/open"
      "-a"
      "Raycast"
    ];
    RunAtLoad = true;
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  home-manager.users.soft = import ../../modules/home/darwin.nix;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}

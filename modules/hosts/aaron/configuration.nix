{
  self,
  pkgs,
  lib,
  # nixpkgs-darwin-pins,
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

  # Determinate Nix manages the daemon and GC; nix-darwin must not conflict.
  nix.enable = false;

  # Determinate Nix ignores nix.settings; it manages /etc/nix/nix.conf itself
  # and provides /etc/nix/nix.custom.conf for user overrides.
  environment.etc."nix/nix.custom.conf".text = ''
    trusted-users = root @admin
  '';

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "aaron";
  networking.computerName = "aaron";

  # Packages pinned to older nixpkgs until binary cache is available.
  # Remove entries once the package has a cached build for aarch64-darwin.
  # nixpkgs.overlays = [
  # (_final: _prev: {
  # inherit (nixpkgs-darwin-pins.legacyPackages.aarch64-darwin) deno;
  # })
  # ];

  system = {
    primaryUser = "soft";

    activationScripts.postActivation.text = ''
      ln --symbolic --force --no-dereference /Users/soft/setup /etc/nix-darwin

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
      uid = 501;
      shell = lib.getExe zsh-wrapped;
      home = "/Users/soft";
    };
  };

  environment.shells = [ zsh-wrapped ];

  environment.systemPackages =
    (with pkgs; [
      betterdisplay
      watch
      raycast
      defaultbrowser
      ghostty-bin.terminfo
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

  homebrew = {
    enable = true;
    casks = [
      "bambu-studio"
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

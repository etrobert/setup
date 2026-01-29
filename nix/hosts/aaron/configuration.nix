{ pkgs, lib, ... }:
let
  dockApps = import ../../dock-apps.nix;

  skhdAppBindings = lib.concatStringsSep "\n" (
    lib.imap1 (i: app: ''alt - ${toString i} : open "${app.path}"'') dockApps
  );
in
{
  imports = [ ../../modules/common.nix ];

  allowedUnfreePackages = [ "raycast" ];

  nix.gc.interval = {
    Hour = 0;
    Minute = 0;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    primaryUser = "soft";

    activationScripts.postActivation.text = ''
      ${pkgs.defaultbrowser}/bin/defaultbrowser firefox
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
  users.knownUsers = [
    "soft"
    "etiennerobert"
  ];

  users.users = {
    soft = {
      uid = 505;
      shell = pkgs.zsh;
      home = "/Users/soft";
    };

    etiennerobert = {
      uid = 501;
      shell = pkgs.zsh;
      home = "/Users/etiennerobert";
    };
  };

  environment.shells = [ pkgs.zsh ];

  environment.systemPackages = with pkgs; [
    watch
    raycast
    defaultbrowser
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

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # TODO: Remove once mac uses the same username
  age.secrets = {
    openai-api-key.group = "admin";
    openai-api-key.mode = "0440";
    gemini-api-key.group = "admin";
    gemini-api-key.mode = "0440";
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}

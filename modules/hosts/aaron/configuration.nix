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

  # Workaround for NixOS/nixpkgs#480849: building llvmPackages_18.compiler-rt
  # on Darwin fails because Apple SDK 26.4 ships libc++ 21, which dropped the
  # fallbacks for __builtin_ctzg/__builtin_clzg — builtins that Clang 18 does
  # not recognize. Mirror the fix from NixOS/nixpkgs#523142 by disabling the
  # C++ components of compiler-rt 18 here.
  #
  # TODO: remove this overlay once nixos-unstable advances past the fix.
  # Trigger: NixOS/nixpkgs#523142 (or its replacement) is merged AND lands in
  # nixos-unstable. Verify by deleting the overlay block below and running
  # `nix build .#darwinConfigurations.aaron.system` — if it succeeds, delete
  # for good. If it still errors with `__builtin_ctzg`, keep the overlay.
  compilerRtOverlay = _final: prev: {
    llvmPackages_18 = prev.llvmPackages_18.overrideScope (
      _llvmFinal: llvmPrev: {
        compiler-rt-libc = llvmPrev.compiler-rt-libc.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [
            (lib.cmakeBool "COMPILER_RT_BUILD_XRAY" false)
            (lib.cmakeBool "COMPILER_RT_BUILD_LIBFUZZER" false)
            (lib.cmakeBool "COMPILER_RT_BUILD_MEMPROF" false)
            (lib.cmakeBool "COMPILER_RT_BUILD_ORC" false)
          ];
        });
      }
    );
  };
in
{
  allowedUnfreePackages = [
    "betterdisplay"
    "raycast"
  ];

  # Determinate Nix manages the daemon and GC; nix-darwin must not conflict.
  nix.enable = false;

  environment = {
    # Determinate Nix ignores nix.settings; it manages /etc/nix/nix.conf itself
    # and provides /etc/nix/nix.custom.conf for user overrides.
    etc."nix/nix.custom.conf".text = ''
      trusted-users = root @admin
    '';

    shells = [ zsh-wrapped ];

    systemPackages =
      (with pkgs; [
        betterdisplay
        watch
        raycast
        defaultbrowser
        ghostty-bin.terminfo
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

  nixpkgs.overlays = [
    compilerRtOverlay
  ];

  # Workaround: nix-darwin's darwin-manual-html builds with
  # `nixos-render-docs manual html --toc-depth`, but nixos-unstable removed
  # `--toc-depth` in favour of `--sidebar-depth`, so the HTML manual fails to
  # build. It is pulled in two ways, both disabled (here and via
  # system.tools.darwin-uninstaller.enable below):
  #   - documentation.doc.enable → aaron's own system-path (manualHTML + the
  #     `darwin-help` command)
  #   - the darwin-uninstaller embeds a reference system (via a fresh, un-
  #     overlaid nixpkgs) whose default system-path also builds the manual
  # Man pages are unaffected.
  #
  # TODO: remove both once nix-darwin's doc/manual passes `--sidebar-depth`
  # (upstream fix nix-darwin/nix-darwin#1819, tracking issue #1817) lands in the
  # pinned input. Verify by deleting them and running
  # `nix build .#darwinConfigurations.aaron.system` — if it succeeds, drop them.
  documentation.doc.enable = false;

  system = {
    # See the darwin-manual-html workaround note above documentation.doc.enable.
    tools.darwin-uninstaller.enable = false;

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

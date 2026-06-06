{
  self,
  pkgs,
  lib,
  options,
  ...
}:
let
  dockApps = import (self + /lib/dock-apps.nix);

  skhdAppBindings = lib.concatStringsSep "\n" (
    lib.imap1 (i: app: ''alt - ${toString i} : open "${app.path}"'') dockApps
  );

  wallpaper = self + /assets/saint-levant.jpg;

  # Models to ensure are present, pulled declaratively by the launchd agent
  # below. The Ollama app cask handles serving/GPU/updates but not models.
  ollamaModels = [ "qwen3:8b" ];

  # Wait for the ollama server, then pull each model via the HTTP API.
  # /api/pull is a no-op for models already present, so this is safe to re-run.
  ollamaLoadModels = pkgs.writeShellApplication {
    name = "ollama-load-models";
    runtimeInputs = [
      pkgs.curl
      pkgs.coreutils
    ];
    inheritPath = false;
    # SC2043: the loop runs once today (single model) but generalises to many.
    excludeShellChecks = [ "SC2043" ];
    text = ''
      host="http://localhost:11434"
      for _ in $(seq 1 60); do
        curl --silent --fail "$host/api/tags" >/dev/null 2>&1 && break
        sleep 1
      done
      for model in ${lib.escapeShellArgs ollamaModels}; do
        echo "Ensuring model: $model"
        curl --silent --fail "$host/api/pull" \
          --data "{\"model\": \"$model\", \"stream\": false}" >/dev/null
      done
    '';
  };

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

    # manifold 3.5.0's test binary traps (Trace/BPT trap: 5) on aarch64-darwin
    # at Manifold.GetNormalLegacyContract, failing openscad's build. The library
    # itself compiles fine, so skip its check phase. Scoped to aaron so the
    # Linux hosts keep using the cached, test-passing manifold.
    #
    # TODO: remove this overlay once manifold's darwin test no longer crashes.
    # Trigger: a manifold version past 3.5.0 lands in nixos-unstable. Verify by
    # deleting the overlay entry and running
    # `nix build .#darwinConfigurations.aaron.system` — if openscad builds,
    # delete for good. The version assertion below fails on the next bump to
    # force a re-check.
    (_final: prev: {
      manifold =
        assert lib.assertMsg (prev.manifold.version == "3.5.0")
          "manifold is no longer 3.5.0 — re-check whether the darwin test still crashes and drop this overlay in modules/hosts/aaron/configuration.nix if it is fixed.";
        prev.manifold.overrideAttrs (_: {
          doCheck = false;
        });
    })
  ];

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

  homebrew = {
    enable = true;
    casks = [
      "bambu-studio"
      "sonos"
      "vlc"
      "whatsapp"
    ];
  };

  # Self-cleaning guard: when nix-darwin gains a native services.ollama module
  # (https://github.com/LnL7/nix-darwin/pull/972) the assertion fails, prompting
  # us to replace the hand-rolled agents below with `services.ollama.enable`.
  #
  # We deliberately do NOT guard on the homebrew formula fix
  # (https://github.com/Homebrew/homebrew-core/issues/285917): migrating to brew
  # once it ships llama-server again is plausible, but Nix evaluation is pure and
  # offline, so it cannot inspect a homebrew bottle's contents or an issue's
  # status — that condition is not expressible as a Nix check. The native module
  # is the better target anyway (pure, declarative, flake-pinned).
  assertions = [
    {
      assertion = !(options.services ? ollama);
      message = ''
        nix-darwin now provides services.ollama. Replace aaron's hand-rolled
        ollama launchd agents (serve + load-models) with the native module and
        delete this guard.
      '';
    }
  ];

  # nix-darwin has no services.ollama, and the homebrew ollama formula is broken
  # for inference on macOS ARM since 0.30.x (ships no llama-server; see
  # Homebrew/homebrew-core#285917). The cask works but is a GUI app. So run the
  # nixpkgs build (complete, with its own runner + embedded Metal) as a user
  # agent. It must be a *user* agent, not a system daemon: launchd does not set
  # $HOME for it, so set it explicitly or ollama panics with "$HOME is not
  # defined" when locating ~/.ollama.
  launchd.user.agents.ollama = {
    serviceConfig = {
      Label = "com.ollama.serve";
      ProgramArguments = [
        "${lib.getExe pkgs.ollama}"
        "serve"
      ];
      EnvironmentVariables.HOME = "/Users/soft";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/ollama.log";
      StandardErrorPath = "/tmp/ollama.log";
    };
  };

  # One-shot user agent: pull the declared models once the serve agent is up.
  # Idempotent (/api/pull is a no-op for present models), so it is safe to
  # re-run on every login.
  launchd.user.agents.ollama-load-models = {
    serviceConfig = {
      Label = "com.ollama.load-models";
      ProgramArguments = [ "${lib.getExe ollamaLoadModels}" ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/ollama-load-models.log";
      StandardErrorPath = "/tmp/ollama-load-models.log";
    };
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

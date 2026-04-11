_: {
  flake.homeModules.common =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      symlink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/setup/${path}";
    in
    {
      home = {
        username = "soft";

        file = {
          ".config/home-manager".source = symlink "nix";

          ".prettierrc".text = builtins.toJSON { proseWrap = "always"; };

          ".profile".source = ../../../profile/.profile;

          ".config/nvim".source = symlink "nvim/.config/nvim";

          ".config/ghostty/config".source = symlink "ghostty/.config/ghostty/config";
        };

        # This value determines the Home Manager release that your
        # configuration is compatible with. This helps avoid breakage
        # when a new Home Manager release introduces backwards
        # incompatible changes.
        #
        # You can update Home Manager without changing this value. See
        # the Home Manager release notes for a list of state version
        # changes in each release.
        stateVersion = "25.11";
      };

      programs = {
        firefox = {
          enable = true;
          nativeMessagingHosts = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.firefoxpwa ];
          policies = {
            PasswordManagerEnabled = false;
            SearchEngines = {
              Default = "DuckDuckGo";
            };
            ExtensionSettings = {
              "uBlock0@raymondhill.net" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                installation_mode = "force_installed";
                default_area = "menupanel";
              };
              "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
                installation_mode = "force_installed";
                default_area = "navbar";
              };
              "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
                installation_mode = "force_installed";
                default_area = "menupanel";
              };
            };
          };
          profiles.default = {
            settings = {
              # Enable the new sidebar + vertical tabs via user prefs (policies block these).
              "sidebar.revamp" = true;
              "sidebar.verticalTabs" = true;
              "browser.ctrlTab.sortByRecentlyUsed" = true;
              "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
            };
          };
        };
      };

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    };
}

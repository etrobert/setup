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

      browserConfig = import ../../browser-config.nix { inherit lib; };
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
          policies = browserConfig.sharedPolicies;
          profiles.default = {
            settings = browserConfig.sharedSettings // {
              # Enable the new sidebar + vertical tabs via user prefs (policies block these).
              "sidebar.revamp" = true;
              "sidebar.verticalTabs" = true;
            };
          };
        };
      };

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    };
}

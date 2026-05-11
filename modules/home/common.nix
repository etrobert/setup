_: {
  flake.homeModules.common =
    { config, ... }:
    let
      symlink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/setup/${path}";
    in
    {
      home = {
        username = "soft";

        file = {
          ".config/home-manager".source = symlink ".";

          ".prettierrc".text = builtins.toJSON { proseWrap = "always"; };
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

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    };
}

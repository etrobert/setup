{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.snacks-nvim;
      luaConfig = /* lua */ ''
        require("snacks").setup({ image = {} })
      '';
      extraPackages =
        with pkgs;
        [ imagemagick ]
        ++ lib.optionals stdenv.isDarwin [ ghostty-bin ]
        ++ lib.optionals stdenv.isLinux [ ghostty ];
    }
  ];
}

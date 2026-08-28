{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.snacks-nvim;
      config = /* lua */ ''
        require("snacks").setup({ image = {} })
      '';
      extraPackages =
        with pkgs;
        [ imagemagick ]
        ++ lib.optionals stdenv.hostPlatform.isDarwin [ ghostty-bin ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [ ghostty ];
    }
  ];
}

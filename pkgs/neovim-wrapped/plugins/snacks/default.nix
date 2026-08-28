{ pkgs, lib, ... }:
{
  # telescope's config calls require("snacks.image") when it loads, so Snacks
  # has to be set up before any other plugin's config runs.
  plugins = lib.mkBefore [
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

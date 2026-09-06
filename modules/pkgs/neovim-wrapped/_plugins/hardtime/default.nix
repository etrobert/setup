{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.hardtime-nvim;
      config = /* lua */ ''
        require("hardtime").setup()
      '';
    }
  ];
}

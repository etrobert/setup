{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.hardtime-nvim;
      luaConfig = /* lua */ ''
        require("hardtime").setup()
      '';
    }
  ];
}

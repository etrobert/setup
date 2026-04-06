{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.gitsigns-nvim;
      luaConfig = builtins.readFile ./config.lua;
    }
  ];
}

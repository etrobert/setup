{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.octo-nvim;
      luaConfig = builtins.readFile ./config.lua;
      extraPackages = with pkgs; [ gh ];
    }
  ];
}

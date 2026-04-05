{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.octo-nvim;
      luaConfig = builtins.readFile ./config.lua;
      extraPackages = with pkgs; [ gh ];
    }
    { plugin = pkgs.vimPlugins.nvim-web-devicons; }
  ];
}

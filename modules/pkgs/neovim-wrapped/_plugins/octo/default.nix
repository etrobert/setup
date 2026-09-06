{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.octo-nvim;
      config = builtins.readFile ./config.lua;
      extraPackages = with pkgs; [ gh ];
    }
    { plugin = pkgs.vimPlugins.nvim-web-devicons; }
    { plugin = pkgs.vimPlugins.plenary-nvim; }
  ];
}

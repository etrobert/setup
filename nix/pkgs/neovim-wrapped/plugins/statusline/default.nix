{ pkgs, ... }:
let
  statusline = pkgs.vimUtils.buildVimPlugin {
    name = "statusline";
    src = ./src;
    # Dependencies used for check phase
    dependencies = [ pkgs.vimPlugins.catppuccin-nvim ];
  };
in
{
  plugins = [
    { plugin = pkgs.vimPlugins.catppuccin-nvim; }
    { plugin = pkgs.vimPlugins.nvim-web-devicons; }
    { plugin = statusline; }
  ];
}

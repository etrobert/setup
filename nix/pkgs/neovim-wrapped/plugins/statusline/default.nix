{ pkgs, ... }:
let
  statusline = pkgs.vimUtils.buildVimPlugin {
    name = "statusline";
    src = ./src;
    # Dependencies used for check phase
    dependencies = [ pkgs.vimPlugins.catppuccin-nvim pkgs.vimPlugins.gitsigns-nvim ];
  };
in
{
  plugins = [
    { plugin = pkgs.vimPlugins.catppuccin-nvim; }
    { plugin = pkgs.vimPlugins.nvim-web-devicons; }
    { plugin = pkgs.vimPlugins.vim-fugitive; }
    { plugin = pkgs.vimPlugins.gitsigns-nvim; }
    { plugin = statusline; }
  ];
}

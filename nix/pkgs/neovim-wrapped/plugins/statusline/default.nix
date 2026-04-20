{ pkgs, ... }:
let
  dependencies = with pkgs.vimPlugins; [
    catppuccin-nvim
    nvim-web-devicons
    vim-fugitive
    gitsigns-nvim
  ];

  statusline = pkgs.vimUtils.buildVimPlugin {
    name = "statusline";
    src = ./src;
    inherit dependencies;
  };
in
{
  plugins = map (plugin: { inherit plugin; }) dependencies ++ [ { plugin = statusline; } ];
}

{ pkgs, ... }:
let
  dependencies = with pkgs.vimPlugins; [
    catppuccin-nvim
    nvim-web-devicons
    vim-fugitive
    gitsigns-nvim
  ];

  statusline = pkgs.vimUtils.buildVimPlugin {
    pname = "statusline";
    version = "0";
    src = ./src;
    inherit dependencies;
  };
in
{
  plugins = map (plugin: { inherit plugin; }) dependencies ++ [ { plugin = statusline; } ];
}

{ pkgs, ... }:
{
  plugins = [
    { plugin = pkgs.vimPlugins.vim-surround; }
    { plugin = pkgs.vimPlugins.vim-repeat; }
  ];
}

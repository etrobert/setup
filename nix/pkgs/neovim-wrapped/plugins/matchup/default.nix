{ pkgs, ... }:
{
  plugins = [ { plugin = pkgs.vimPlugins.vim-matchup; } ];
}

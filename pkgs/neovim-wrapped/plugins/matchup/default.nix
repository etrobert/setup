{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.vim-matchup;
      config = /* lua */ ''
        vim.g.matchup_matchparen_offscreen = { method = "popup" }
      '';
    }
  ];
}

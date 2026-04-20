{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.vim-matchup;
      luaConfig = /* lua */ ''
        vim.g.matchup_matchparen_offscreen = { method = "popup" }
      '';
    }
  ];
}

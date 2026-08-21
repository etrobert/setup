{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
      config = builtins.readFile ./config.lua;
    }
    # Not part of nvim-treesitter's grammar set.
    { plugin = pkgs.neovimUtils.grammarToPlugin pkgs.tree-sitter-grammars.tree-sitter-openscad; }
    { plugin = pkgs.vimPlugins.nvim-treesitter-textobjects; }
  ];
}

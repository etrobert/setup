{ pkgs, lib, ... }:
let
  openscad =
    assert lib.assertMsg (!(pkgs.vimPlugins.nvim-treesitter.grammarPlugins ? openscad))
      "nvim-treesitter now ships an openscad grammar — drop the explicit entry in pkgs/neovim-wrapped/plugins/treesitter/default.nix";
    pkgs.neovimUtils.grammarToPlugin pkgs.tree-sitter-grammars.tree-sitter-openscad;
in
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
      config = builtins.readFile ./config.lua;
    }
    { plugin = openscad; }
    { plugin = pkgs.vimPlugins.nvim-treesitter-textobjects; }
  ];
}

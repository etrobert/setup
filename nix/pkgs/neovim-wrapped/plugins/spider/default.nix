{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-spider;
      luaConfig = /* lua */ ''require("spider").setup({ skipInsignificantPunctuation = false })'';
    }
  ];
}

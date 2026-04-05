{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.fidget-nvim;
      luaConfig = /* lua */ ''require("fidget").setup({})'';
    }
  ];
}

{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.harpoon2;
      luaConfig = builtins.readFile ./config.lua;
    }
    { plugin = pkgs.vimPlugins.plenary-nvim; }
  ];
}

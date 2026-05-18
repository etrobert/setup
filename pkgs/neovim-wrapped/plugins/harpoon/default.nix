{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.harpoon2;
      config = builtins.readFile ./config.lua;
    }
    { plugin = pkgs.vimPlugins.plenary-nvim; }
  ];
}

{
  self',
  pkgs,
  with-git-wrapped,
  ...
}:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.gitsigns-nvim;
      luaConfig = builtins.readFile ./config.lua;
      extraPackages = if with-git-wrapped then [ self'.packages.git-wrapped ] else with pkgs; [ git ];
    }
  ];
}

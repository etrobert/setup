{
  git-wrapped,
  pkgs,
  with-git-wrapped,
  ...
}:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.gitsigns-nvim;
      config = builtins.readFile ./config.lua;
      extraPackages = if with-git-wrapped then [ git-wrapped ] else with pkgs; [ git ];
    }
  ];
}

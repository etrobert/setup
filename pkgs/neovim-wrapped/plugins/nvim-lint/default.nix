{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-lint;
      extraPackages = with pkgs; [
        markdownlint-cli2
        yamllint
      ];
      config = builtins.readFile ./config.lua;
    }
  ];
}

{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-lint;
      extraPackages = with pkgs; [ markdownlint-cli2 ];
      luaConfig = builtins.readFile ./config.lua;
    }
  ];
}

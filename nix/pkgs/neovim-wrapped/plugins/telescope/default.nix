{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.telescope-nvim;
      luaConfig = builtins.readFile ./config.lua;
      extraPackages = with pkgs; [
        fd
        ripgrep
      ];
    }
    { plugin = pkgs.vimPlugins.telescope-ui-select-nvim; }
    { plugin = pkgs.vimPlugins.telescope-fzf-native-nvim; }
    { plugin = pkgs.vimPlugins.plenary-nvim; }
  ];
}

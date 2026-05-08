{ pkgs, ... }:
let
  telescope-extras = pkgs.vimUtils.buildVimPlugin {
    name = "telescope-extras";
    src = ./telescope-extras;
    dependencies = [ pkgs.vimPlugins.telescope-nvim pkgs.vimPlugins.plenary-nvim ];
  };
in
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
    { plugin = telescope-extras; }
  ];
}

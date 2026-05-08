{ pkgs, ... }:
let
  set = pkgs.vimUtils.buildVimPlugin {
    name = "set";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = set;
      luaConfig = "require('set')";
    }
  ];
}

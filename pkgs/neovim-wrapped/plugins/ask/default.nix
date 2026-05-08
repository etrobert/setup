{ pkgs, ... }:
let
  ask = pkgs.vimUtils.buildVimPlugin {
    name = "ask";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = ask;
      luaConfig = "require('ask').setup()";
    }
  ];
}

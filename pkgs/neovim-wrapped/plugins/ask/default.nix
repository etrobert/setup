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
      config = "require('ask').setup()";
    }
  ];
}

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
      config = "require('set')";
    }
  ];
}

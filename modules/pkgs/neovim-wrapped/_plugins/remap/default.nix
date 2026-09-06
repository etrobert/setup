{ pkgs, ... }:
let
  remap = pkgs.vimUtils.buildVimPlugin {
    name = "remap";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = remap;
      config = "require('remap')";
    }
  ];
}

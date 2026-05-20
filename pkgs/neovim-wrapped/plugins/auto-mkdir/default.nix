{ pkgs, ... }:
let
  auto-mkdir = pkgs.vimUtils.buildVimPlugin {
    name = "auto-mkdir";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = auto-mkdir;
      config = "require('auto_mkdir')";
    }
  ];
}

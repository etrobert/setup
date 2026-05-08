{ pkgs, ... }:
let
  tsc-compiler = pkgs.vimUtils.buildVimPlugin {
    name = "tsc-compiler";
    src = ./src;
  };
in
{
  plugins = [
    { plugin = tsc-compiler; }
  ];
}

{ pkgs, ... }:
let
  statix-compiler = pkgs.vimUtils.buildVimPlugin {
    pname = "statix-compiler";
    version = "0";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = statix-compiler;
      extraPackages = [ pkgs.statix ];
    }
  ];
}

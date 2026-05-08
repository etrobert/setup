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
      # Note: This shadows local versions of statix, eg. provided by direnv
      extraPackages = [ pkgs.statix ];
    }
  ];
}

{ pkgs, self', ... }:
let
  deadnix-compiler = pkgs.vimUtils.buildVimPlugin {
    pname = "deadnix-compiler";
    version = "0";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = deadnix-compiler;
      extraPackages = [ self'.packages.deadnix-errfmt ];
    }
  ];
}

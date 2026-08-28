{ pkgs, deadnix-errfmt, ... }:
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
      extraPackages = [ deadnix-errfmt ];
    }
  ];
}

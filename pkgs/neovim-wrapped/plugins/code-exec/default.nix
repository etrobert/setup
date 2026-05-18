{ pkgs, ... }:
let
  code-exec = pkgs.vimUtils.buildVimPlugin {
    name = "code-exec";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = code-exec;
      config = "require('code_exec').setup()";
    }
  ];
}

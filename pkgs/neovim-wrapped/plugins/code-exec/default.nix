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
      luaConfig = "require('code_exec').setup()";
    }
  ];
}

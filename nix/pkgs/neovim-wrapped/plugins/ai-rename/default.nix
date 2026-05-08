{ pkgs, ... }:
let
  ai-rename = pkgs.vimUtils.buildVimPlugin {
    name = "ai-rename";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = ai-rename;
      luaConfig = "require('ai_rename').setup()";
    }
  ];
}

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
      config = "require('ai_rename').setup()";
    }
  ];
}

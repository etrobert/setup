{ pkgs, ... }:
let
  bookmarks = pkgs.vimUtils.buildVimPlugin {
    name = "bookmarks";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = bookmarks;
      luaConfig = "require('bookmarks').setup()";
    }
  ];
}

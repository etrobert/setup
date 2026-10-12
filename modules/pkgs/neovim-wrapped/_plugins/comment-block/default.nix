{ pkgs, ... }:
let
  comment-block = pkgs.vimUtils.buildVimPlugin {
    name = "comment-block";
    src = ./src;
  };
in
{
  plugins = [ { plugin = comment-block; } ];
}

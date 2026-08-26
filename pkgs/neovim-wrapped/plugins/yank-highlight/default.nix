{ pkgs, ... }:
let
  yank-highlight = pkgs.vimUtils.buildVimPlugin {
    name = "yank-highlight";
    src = ./src;
  };
in
{
  plugins = [ { plugin = yank-highlight; } ];
}

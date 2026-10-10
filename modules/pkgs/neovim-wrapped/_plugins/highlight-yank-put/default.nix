{ pkgs, ... }:
let
  highlight-yank-put = pkgs.vimUtils.buildVimPlugin {
    name = "highlight-yank-put";
    src = ./src;
  };
in
{
  plugins = [ { plugin = highlight-yank-put; } ];
}

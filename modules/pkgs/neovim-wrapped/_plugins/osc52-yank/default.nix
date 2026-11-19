{ pkgs, ... }:
let
  osc52-yank = pkgs.vimUtils.buildVimPlugin {
    name = "osc52-yank";
    src = ./src;
  };
in
{
  plugins = [ { plugin = osc52-yank; } ];
}

{ pkgs, ... }:
let
  trim-whitespace = pkgs.vimUtils.buildVimPlugin {
    name = "trim-whitespace";
    src = ./src;
  };
in
{
  plugins = [ { plugin = trim-whitespace; } ];
}

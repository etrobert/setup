{ pkgs, ... }:
let
  completion = pkgs.vimUtils.buildVimPlugin {
    name = "completion";
    src = ./src;
  };
in
{
  plugins = [ { plugin = completion; } ];
}

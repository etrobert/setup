{ pkgs, ... }:
let
  startup-banner = pkgs.vimUtils.buildVimPlugin {
    name = "startup-banner";
    src = ./src;
  };
in
{
  plugins = [
    {
      plugin = startup-banner;
      luaConfig = "require('startup_banner').setup()";
    }
  ];
}

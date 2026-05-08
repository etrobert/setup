{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.copilot-vim;
      extraPackages = with pkgs; [ nodejs_24 ];
    }
  ];
}

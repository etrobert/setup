{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.fidget-nvim;
      config = /* lua */ ''require("fidget").setup({})'';
    }
  ];
}

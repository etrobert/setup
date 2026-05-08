{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.lazydev-nvim;
      luaConfig = /* lua */ ''
        require("lazydev").setup({
        	library = { { path = "''${3rd}/luv/library", words = { "vim%.uv" } } },
        })
      '';
    }
  ];
}

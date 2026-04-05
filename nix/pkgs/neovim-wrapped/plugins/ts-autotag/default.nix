{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.nvim-ts-autotag;
      luaConfig = /* lua */ ''
        require("nvim-ts-autotag").setup({
        	opts = {
        		enable_close = false,
        		enable_rename = true,
        		enable_close_on_slash = false,
        	},
        })
      '';
    }
  ];
}

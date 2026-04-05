{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.which-key-nvim;
      luaConfig = /* lua */ ''
        require("which-key").setup({
        	spec = {
        		{ "<leader>b", group = "Buffer" },
        		{ "<leader>g", group = "Telescope Git" },
        		{ "<leader>f", group = "Telescope Files" },
        		{ "<leader>o", group = "Octo" },
        	},
        })
      '';
    }
  ];
}

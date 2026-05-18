{ pkgs, ... }:
{
  plugins = [
    {
      plugin = pkgs.vimPlugins.bufferline-nvim;
      config = /* lua */ ''
        require("bufferline").setup({
        	options = {
        		diagnostics = "nvim_lsp",
        		numbers = "buffer_id",
        		show_buffer_close_icons = false,
        	},
        })
      '';
    }
  ];
}

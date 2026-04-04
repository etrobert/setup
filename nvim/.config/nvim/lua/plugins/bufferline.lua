return {
	src = "https://github.com/akinsho/bufferline.nvim",
	config = function()
		require("bufferline").setup({
			options = { diagnostics = "nvim_lsp", numbers = "buffer_id", show_buffer_close_icons = false },
		})
	end,
}

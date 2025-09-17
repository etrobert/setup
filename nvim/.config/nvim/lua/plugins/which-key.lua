vim.pack.add({ "https://github.com/folke/which-key.nvim" })

require("which-key").setup({
	spec = {
		{ "<leader>b", group = "Buffer" },
		{ "<leader>g", group = "Telescope Git" },
		{ "<leader>f", group = "Telescope Files" },
	},
})

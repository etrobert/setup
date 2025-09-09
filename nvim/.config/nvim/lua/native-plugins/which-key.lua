vim.pack.add({ "https://github.com/folke/which-key.nvim" })

vim.o.timeout = true
vim.o.timeoutlen = 1000

require("which-key").setup({
	spec = {
		{ "<leader>b", group = "Buffer" },
		{ "<leader>g", group = "Telescope Git" },
		{ "<leader>f", group = "Telescope Files" },
		{ "<leader>x", group = "Trouble" },
	},
})